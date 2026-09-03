$ErrorActionPreference = 'Stop'

$root = "C:\Users\dieud\Documents\MOI\PROJETS\ALERTCONTACTS-V3\alertcontacts"
$outDir = Join-Path $root "docs"
$outPath = Join-Path $outDir "Rapport-Analytics-PostHog-AlertContacts-2026-09-03.docx"
$tempDir = Join-Path $env:TEMP ("alertcontacts-analytics-report-" + [guid]::NewGuid().ToString("N"))

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

function XmlEscape([string]$value) {
    return [System.Security.SecurityElement]::Escape($value)
}

function RunXml([string]$text, [bool]$bold = $false, [string]$color = $null, [int]$sizeHalfPoints = 22) {
    $rPr = "<w:sz w:val=`"$sizeHalfPoints`"/><w:szCs w:val=`"$sizeHalfPoints`"/>"
    if ($bold) { $rPr = "<w:b/>" + $rPr }
    if ($color) { $rPr += "<w:color w:val=`"$color`"/>" }
    return "<w:r><w:rPr>$rPr</w:rPr><w:t xml:space=`"preserve`">$(XmlEscape $text)</w:t></w:r>"
}

function Paragraph([string]$text, [string]$style = "Normal") {
    $escaped = XmlEscape $text
    return "<w:p><w:pPr><w:pStyle w:val=`"$style`"/></w:pPr><w:r><w:t xml:space=`"preserve`">$escaped</w:t></w:r></w:p>"
}

function RichParagraph([array]$runs, [string]$style = "Normal") {
    return "<w:p><w:pPr><w:pStyle w:val=`"$style`"/></w:pPr>$($runs -join '')</w:p>"
}

function Bullet([string]$text) {
    $escaped = XmlEscape $text
    return "<w:p><w:pPr><w:pStyle w:val=`"Bullet`"/></w:pPr><w:r><w:t xml:space=`"preserve`">$escaped</w:t></w:r></w:p>"
}

function PageBreak {
    return "<w:p><w:r><w:br w:type=`"page`"/></w:r></w:p>"
}

function Cell([string]$text, [bool]$header = $false) {
    $fill = if ($header) { "<w:shd w:fill=`"E8EEF5`"/>" } else { "" }
    $boldStart = if ($header) { "<w:b/>" } else { "" }
    return "<w:tc><w:tcPr><w:tcW w:w=`"2000`" w:type=`"dxa`"/>$fill</w:tcPr><w:p><w:r><w:rPr>$boldStart<w:sz w:val=`"18`"/><w:szCs w:val=`"18`"/></w:rPr><w:t xml:space=`"preserve`">$(XmlEscape $text)</w:t></w:r></w:p></w:tc>"
}

function AddZipTextEntry($archive, [string]$entryName, [string]$content) {
    $entry = $archive.CreateEntry($entryName)
    $stream = $entry.Open()
    try {
        $writer = [System.IO.StreamWriter]::new($stream, [System.Text.Encoding]::UTF8)
        try {
            $writer.Write($content)
        } finally {
            $writer.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}

function Table([array]$headers, [array]$rows) {
    $xml = "<w:tbl><w:tblPr><w:tblW w:w=`"9360`" w:type=`"dxa`"/><w:tblBorders><w:top w:val=`"single`" w:sz=`"4`" w:color=`"D9E2EC`"/><w:left w:val=`"single`" w:sz=`"4`" w:color=`"D9E2EC`"/><w:bottom w:val=`"single`" w:sz=`"4`" w:color=`"D9E2EC`"/><w:right w:val=`"single`" w:sz=`"4`" w:color=`"D9E2EC`"/><w:insideH w:val=`"single`" w:sz=`"4`" w:color=`"D9E2EC`"/><w:insideV w:val=`"single`" w:sz=`"4`" w:color=`"D9E2EC`"/></w:tblBorders><w:tblCellMar><w:top w:w=`"80`" w:type=`"dxa`"/><w:bottom w:w=`"80`" w:type=`"dxa`"/><w:start w:w=`"120`" w:type=`"dxa`"/><w:end w:w=`"120`" w:type=`"dxa`"/></w:tblCellMar></w:tblPr>"
    $xml += "<w:tr>"
    foreach ($h in $headers) { $xml += Cell $h $true }
    $xml += "</w:tr>"
    foreach ($row in $rows) {
        $xml += "<w:tr>"
        foreach ($c in $row) { $xml += Cell ([string]$c) $false }
        $xml += "</w:tr>"
    }
    return $xml + "</w:tbl>"
}

$insights = @(
    @("Activation - Funnel onboarding complet", "Funnel", "Lit la progression onboarding -> invitation -> completion. A utiliser pour voir ou les nouveaux utilisateurs abandonnent."),
    @("Activation - Volumes events onboarding", "Trend", "Suit les volumes journaliers auth/onboarding. Sert a detecter une rupture de tracking ou un changement de trafic."),
    @("Activation - Personas selectionnees", "Breakdown", "Repartition des personas choisis. Sert a comprendre pour qui le produit attire au depart."),
    @("Tracking - Qualite events et identite", "Controle qualite", "Compare event count, personnes et distinct_id. C'est le radar anti-doublons et anti-tracking casse."),
    @("Backend - Volumes signaux produit", "Backend", "Isole les signaux Laravel/backfill: invitations, zones, alertes, routes. Plus proche de l'usage reel que les simples ecrans."),
    @("Usage - Routes preview vs started", "Trend", "Compare intention de trajet et usage fort. Preview = interet; started = engagement plus serieux."),
    @("Usage - Reseau securite et alertes", "Trend", "Suit les actions qui creent la valeur reseau: invitation, zone, signalement communautaire."),
    @("Activation - Etat utilisateurs backend", "Table", "Segmente les utilisateurs par tier, contact actif et zones. C'est la lecture la plus directe de l'activation reelle.")
)

$observed = @(
    @("route_previewed", "31", "1", "Interet pour le module trajets"),
    @("backend_person_properties_updated", "11", "11", "Synchronisation des proprietes utilisateurs depuis Laravel"),
    @("contact_invited", "5", "4", "Creation d'invitations de proches"),
    @("route_started", "4", "1", "Trajets vraiment demarres"),
    @("app_shell_reached", "4", "2", "Arrivee dans l'app principale"),
    @("community_alert_created", "3", "2", "Signalements communautaires crees"),
    @("\$screen", "2", "1", "Ecrans mobiles vus"),
    @("zone_created", "1", "1", "Zone de securite creee"),
    @("auth_started / login_success / onboarding_*", "1 chacun", "1", "Premiers signaux onboarding/auth visibles")
)

$backfill = @(
    @("person_properties", "11", "Proprietes utilisateur synchronisees vers PostHog"),
    @("contact_invited", "5", "Invitations historiques envoyees"),
    @("zone_created", "1", "Zones historiques creees"),
    @("community_alert_created_v1", "3", "Signalements V1 historiques"),
    @("route_previewed", "31", "Previsualisations de trajets historiques"),
    @("route_started", "4", "Trajets historiques demarres"),
    @("contact_invitation_accepted, aha, subscription", "0", "Pas de donnees historiques trouvees dans ces categories au moment du dry-run")
)

$events = @(
    @("auth_started", "Mobile", "Authentification", "Un utilisateur commence une tentative de connexion.", "method", "Si ca monte sans login_success, le login bloque."),
    @("login_success", "Mobile", "Authentification", "Connexion reussie cote app.", "method", "Mesure l'acces reel au produit."),
    @("backend_login_success", "Backend", "Authentification", "Connexion validee cote Laravel.", "method, auth_provider, tier", "A comparer avec login_success pour detecter des divergences client/serveur."),
    @("login_failure", "Mobile", "Authentification", "Echec de connexion cote app.", "method, error_code", "Explique les freins d'entree."),
    @("signup_success", "Mobile", "Authentification", "Creation de compte reussie.", "method", "Mesure acquisition compte."),
    @("logout", "Mobile", "Authentification", "Deconnexion volontaire.", "-", "Peut signaler un churn comportemental si frequent."),
    @("password_reset_requested", "Mobile", "Authentification", "Demande de reset mot de passe.", "-", "Indique friction de connexion."),
    @("\$screen", "Mobile", "Navigation", "Vue d'ecran mobile PostHog.", "screen_name, app_version, app_build", "Permet de lire les chemins reels."),
    @("app_shell_reached", "Mobile", "Activation", "L'utilisateur atteint l'interface principale.", "-", "Activation technique minimale."),
    @("onboarding_started", "Mobile", "Onboarding", "Debut de personnalisation/onboarding.", "-", "Point de depart du funnel."),
    @("onboarding_slide_viewed", "Mobile", "Onboarding", "Slide onboarding vue.", "slide_index", "Identifie les slides ou l'attention tombe."),
    @("onboarding_slides_completed", "Mobile", "Onboarding", "Slides terminees.", "-", "Passage vers l'etape suivante."),
    @("onboarding_slides_skipped", "Mobile", "Onboarding", "Slides sautees.", "at_slide", "Mesure impatience ou faible valeur percue."),
    @("onboarding_persona_selected", "Mobile", "Onboarding", "Persona choisi.", "persona", "Segmente les usages attendus."),
    @("invitation_screen_viewed", "Mobile", "Activation reseau", "Ecran d'invitation onboarding vu.", "-", "Mesure exposition a l'action cle."),
    @("onboarding_invitation_sent", "Mobile", "Activation reseau", "Invitation envoyee pendant l'onboarding.", "-", "Premier signal de viralite/reseau."),
    @("onboarding_invitation_skipped", "Mobile", "Activation reseau", "Invitation ignoree pendant l'onboarding.", "-", "Frein a la creation du reseau."),
    @("onboarding_completed", "Mobile", "Activation", "Onboarding termine.", "-", "Fin du funnel initial."),
    @("permission_result", "Mobile", "Permissions", "Resultat d'une demande de permission.", "permission_type, granted", "Explique pourquoi localisation/notifications peuvent echouer."),
    @("contact_invited", "Mobile + Backend", "Reseau securite", "Invitation de proche creee.", "share_level, requires_pin, invitee_known", "Mesure construction du reseau."),
    @("contact_invite_failed", "Mobile + Backend", "Reseau securite", "Creation d'invitation echouee.", "reason", "Detecte limite gratuite, validation ou erreurs."),
    @("invitation_link_opened", "Mobile", "Invitation", "Lien d'invitation ouvert.", "has_prefilled_pin", "Debut du funnel invite."),
    @("invitation_check_succeeded", "Mobile + Backend", "Invitation", "Lien valide.", "requires_pin, share_level", "Mesure les liens utilisables."),
    @("invitation_check_failed", "Mobile + Backend", "Invitation", "Lien invalide, expire ou erreur.", "reason", "Mesure les invitations perdues."),
    @("invitation_accept_started", "Mobile + Backend", "Invitation", "L'utilisateur tente d'accepter.", "has_pin, share_level", "Intention forte cote invite."),
    @("invitation_accept_failed", "Mobile + Backend", "Invitation", "Acceptation echouee.", "reason", "Explique le trou entre intention et relation creee."),
    @("invitation_refused", "Mobile + Backend", "Invitation", "Invitation refusee.", "-", "Signal de non-adhesion."),
    @("contact_invitation_accepted", "Mobile + Backend", "Activation reseau", "Relation creee apres acceptation.", "role, share_level", "Vrai moment d'activation sociale."),
    @("aha_1_contact_accepted", "Mobile + Backend", "Aha moment", "Premier proche actif.", "role", "Aha principal du produit."),
    @("aha_2_contact_on_map", "Mobile", "Aha moment", "Un contact devient visible sur la carte.", "-", "Valeur concrete: voir un proche."),
    @("aha_3_zone_alert_received", "Mobile", "Aha moment", "Alerte zone recue/ouverte.", "-", "Valeur securite percue."),
    @("zone_created", "Mobile + Backend", "Zones", "Zone de securite creee.", "icon, radius_bucket", "Mesure configuration de protection."),
    @("zone_entry_detected", "Mobile", "Zones", "Entree locale detectee.", "-", "Signal operationnel geofencing."),
    @("zone_exit_detected", "Mobile", "Zones", "Sortie locale detectee.", "-", "Signal operationnel geofencing."),
    @("community_alert_created", "Mobile + Backend", "Alertes", "Signalement communautaire cree.", "gravity, type", "Mesure contribution au reseau."),
    @("community_alert_viewed", "Mobile", "Alertes", "Signalement consulte.", "gravity", "Mesure consommation de securite."),
    @("community_alert_confirmed", "Mobile + Backend", "Alertes", "Signalement confirme.", "-", "Mesure qualite/crowdsourcing."),
    @("route_previewed", "Mobile + Backend", "Trajets", "Itineraire previsualise.", "transport_mode, incident_count", "Interet pour le module trajet."),
    @("route_started", "Mobile + Backend", "Trajets", "Trajet demarre.", "transport_mode, avoidance_applied", "Usage fort du module."),
    @("route_incident_detected", "Mobile", "Trajets", "Incident detecte sur trajet.", "gravity, type, report_count_bucket", "Mesure risque rencontre."),
    @("route_avoidance_requested", "Mobile + Backend", "Trajets", "Demande de contournement.", "incident_count", "Signal de valeur premium potentielle."),
    @("route_avoidance_partial", "Mobile + Backend", "Trajets", "Contournement partiel.", "-", "Mesure limite de routing."),
    @("route_incident_notification_opened", "Mobile", "Trajets", "Notification d'incident trajet ouverte.", "-", "Mesure valeur percue des alertes trajet."),
    @("paywall_displayed", "Mobile", "Monetisation", "Paywall affiche.", "trigger", "Debut funnel monetisation."),
    @("paywall_dismissed", "Mobile", "Monetisation", "Paywall ferme sans achat confirme.", "-", "Mesure hesitation/refus."),
    @("paywall_open_failed", "Mobile", "Monetisation", "Paywall impossible a ouvrir.", "trigger, reason", "Detecte config RevenueCat ou erreurs."),
    @("subscription_purchased", "Mobile + Backend", "Monetisation", "Achat confirme.", "tier, billing", "Conversion payante."),
    @("subscription_purchase_failed", "Mobile", "Monetisation", "Achat echoue ou annule.", "reason", "Friction paiement."),
    @("subscription_trial_started", "Mobile + Backend", "Monetisation", "Essai demarre.", "tier, billing", "Entree dans l'offre premium."),
    @("subscription_cancelled / expired / renewed", "Backend", "Monetisation", "Cycle de vie abonnement RevenueCat.", "tier, billing, product", "Mesure retention revenue."),
    @("subscription_restore_requested/succeeded/failed", "Mobile", "Monetisation", "Restauration d'achat.", "reason si echec", "Support abonnements existants."),
    @("subscription_limit_reached", "Backend", "Monetisation", "Limite gratuite atteinte.", "limit_type, limit", "Moments naturels de conversion."),
    @("premium_action_denied", "Backend", "Monetisation", "Action premium bloquee.", "feature, tier", "Mesure demande premium non convertie."),
    @("notification_send_succeeded / failed", "Backend", "Notifications", "FCM envoye ou echoue.", "type, priority, reason", "Qualite livraison serveur."),
    @("fcm_token_registered", "Mobile", "Notifications", "Token FCM transmis/valide.", "refreshed", "Base de reach notification."),
    @("fcm_token_registration_failed", "Mobile", "Notifications", "Token FCM indisponible ou non envoye.", "reason", "Cause des utilisateurs injoignables."),
    @("notification_received", "Mobile", "Notifications", "Push recu par l'app.", "type, app_state", "Mesure reception client."),
    @("notification_displayed", "Mobile", "Notifications", "Notification locale affichee.", "type", "Mesure affichage effectif."),
    @("notification_opened", "Mobile", "Notifications", "Notification ouverte.", "type", "Engagement notification."),
    @("app_status_checked", "Mobile", "Versioning", "Statut minimum version verifie.", "platform, current_build, minimum_build, update_required", "Base du pilotage update forcee."),
    @("forced_update_required", "Mobile + Backend", "Versioning", "Version trop ancienne bloquee.", "platform, current_build, minimum_build", "Impact d'une release obligatoire."),
    @("forced_update_screen_viewed", "Mobile", "Versioning", "Ecran de mise a jour vu.", "has_store_url", "Experience utilisateur du blocage."),
    @("forced_update_store_opened", "Mobile", "Versioning", "Clic vers store.", "success", "Mesure passage vers mise a jour."),
    @("tracker_added / activated / suspended", "Mobile + Backend", "Traceurs GPS", "Cycle de vie traceur.", "status, reason", "Usage materiel/traceurs."),
    @("tracker_telemetry_received / rejected", "Backend", "Traceurs GPS", "Telemetrie recue ou rejetee.", "reason", "Sante ingestion traceurs."),
    @("tracker_geofence_event_created", "Backend", "Traceurs GPS", "Evenement geofence traceur.", "event_type, notification_enabled", "Valeur securite via traceur."),
    @("app_review_prompt", "Mobile", "Satisfaction", "Prompt avis demande ou store ouvert.", "action", "Mesure satisfaction exploitable.")
)

$future = @(
    @("Retention J1/J7/J30 par cohorte", "Savoir si les utilisateurs reviennent apres activation.", "Besoin de volume et d'un event de retour fiable comme app_shell_reached ou session."),
    @("Funnel invitation complet", "Lien ouvert -> check ok -> accept started -> accepted.", "A creer apres deploiement des nouveaux events."),
    @("Sante notifications", "Send succeeded -> received -> displayed -> opened.", "Comparer backend et mobile; attention aux limites des handlers background."),
    @("Monetisation", "paywall_displayed -> purchase/trial -> cancelled/renewed.", "Segmenter par trigger: contact_limit, avoidance_quota, settings."),
    @("Qualite permissions", "permission_result par type et conversion ensuite.", "Ajouter la lecture fine localisation always/while-in-use si disponible."),
    @("Erreurs produit", "Events d'echec metier avec reason stable.", "Eviter les messages bruts; garder des categories."),
    @("Cohortes activation", "Persona + contact actif + zone creee + trajet demarre.", "Necessite plus d'utilisateurs pour etre statistiquement utile.")
)

$doc = @()
$doc += Paragraph "Rapport analytics PostHog - AlertContacts" "Title"
$doc += Paragraph "Date: 3 septembre 2026. Perimetre: application mobile Flutter, backend Laravel, PostHog US project 591000." "Subtitle"
$doc += Paragraph "Conclusion: le socle analytics est maintenant utilisable pour lire l'activation, le reseau de proches, les zones, les alertes communautaires, les trajets, la monetisation, les notifications, les traceurs GPS et la mise a jour forcee. La limite actuelle n'est pas le manque d'events dans le code; c'est le faible volume reel observe dans PostHog et le fait que plusieurs events ajoutes aujourd'hui doivent encore etre deployes avant d'apparaitre dans les dashboards." "Normal"
$doc += Paragraph "Ce rapport distingue trois niveaux: les donnees deja observees dans PostHog, les dashboards/insights deja crees, et les events instrumentes dans le code mais pas encore visibles tant qu'une version deployee ne les envoie pas." "Normal"

$doc += Paragraph "1. Langage des donnees" "Heading1"
$doc += Bullet "Event: action horodatee envoyee a PostHog, par exemple contact_invited ou route_started."
$doc += Bullet "Person: utilisateur regroupe par PostHog. L'objectif est qu'un meme utilisateur garde le meme distinct_id entre mobile et backend."
$doc += Bullet "Distinct ID: identifiant technique utilise pour rattacher les events a une personne. Cote backend, le service privilegie firebase_uid quand il existe."
$doc += Bullet "Property: contexte attache a un event, par exemple share_level, reason, trigger, platform ou current_build."
$doc += Bullet "Insight: graphique ou tableau sauvegarde dans PostHog."
$doc += Bullet "Dashboard: regroupement d'insights pour piloter un sujet produit."
$doc += Bullet "Funnel: suite ordonnee d'events pour mesurer les pertes entre etapes."
$doc += Bullet "Cohorte: segment d'utilisateurs partageant une condition, par exemple has_active_contact=true."

$doc += Paragraph "2. Etat reel observe dans PostHog" "Heading1"
$doc += Paragraph "La requete PostHog sur 180 jours montre actuellement peu de volume. C'est normal a ce stade, mais cela impose de lire les pourcentages avec prudence: quelques utilisateurs peuvent faire varier fortement un taux." "Normal"
$doc += Table @("Event observe", "Events", "Personnes", "Lecture") $observed
$doc += Paragraph "Point prouve: PostHog a signale comme absents de la taxonomie plusieurs events pourtant deja instrumentes ou ajoutes dans le code, par exemple contact_invitation_accepted, aha_1_contact_accepted, route_avoidance_requested, subscription_purchased et les nouveaux events d'invitation/notification. Cela signifie qu'ils n'ont pas encore ete recus recemment par PostHog, pas qu'ils sont inutiles." "Normal"

$doc += Paragraph "3. Dashboard et insights deja crees" "Heading1"
$doc += Paragraph "Dashboard principal: AlertContacts - Activation. URL connue: https://us.posthog.com/project/591000/dashboard/2060063." "Normal"
$doc += Table @("Insight", "Type de lecture", "Comment le lire") $insights
$doc += Paragraph "Les insights par defaut PostHog existent aussi: Active users, Sessions, Pageviews, DAU, WAU, Retention, Top referrers et Visit to interaction funnel. Ils sont utiles comme base, mais les insights AlertContacts sont plus importants car ils parlent le langage produit de l'app." "Normal"

$doc += PageBreak
$doc += Paragraph "4. Catalogue des events et metriques" "Heading1"
$doc += Paragraph "Chaque event ci-dessous doit etre lu comme une phrase metier. Exemple: route_started signifie qu'une personne n'a pas seulement regarde un itineraire; elle l'a demarre. Les proprietes servent a segmenter sans stocker de donnees sensibles." "Normal"
$doc += Table @("Event", "Source", "Parcours", "Signification", "Proprietes principales", "Lecture produit") $events

$doc += PageBreak
$doc += Paragraph "5. Parcours utilisateur mesurables" "Heading1"
$doc += Paragraph "Activation initiale" "Heading2"
$doc += Bullet "auth_started -> login_success -> onboarding_started -> onboarding_slides_completed -> onboarding_persona_selected -> invitation_screen_viewed -> onboarding_completed -> app_shell_reached."
$doc += Bullet "Question produit: les utilisateurs arrivent-ils vraiment dans l'app principale apres l'inscription?"
$doc += Bullet "Signal fort: app_shell_reached. Signal plus fort: has_active_contact=true ou zone_created."
$doc += Paragraph "Creation du reseau de securite" "Heading2"
$doc += Bullet "contact_invited -> invitation_link_opened -> invitation_check_succeeded -> invitation_accept_started -> contact_invitation_accepted -> aha_1_contact_accepted."
$doc += Bullet "Question produit: l'invitation genere-t-elle une relation active ou seulement une intention?"
$doc += Bullet "Les reasons invitation_check_failed et invitation_accept_failed expliquent les pertes: expired, invalid_pin, already_exists, subscription_limit, validation, server_error."
$doc += Paragraph "Zones et alertes" "Heading2"
$doc += Bullet "zone_created mesure la configuration de protection."
$doc += Bullet "zone_entry_detected et zone_exit_detected mesurent le fonctionnement local du geofencing."
$doc += Bullet "community_alert_created, viewed et confirmed mesurent la contribution et la validation communautaire."
$doc += Paragraph "Trajets" "Heading2"
$doc += Bullet "route_previewed mesure l'interet. route_started mesure l'usage fort."
$doc += Bullet "route_avoidance_requested est un signal premium potentiel: l'utilisateur veut eviter un risque."
$doc += Bullet "route_incident_notification_opened mesure si les alertes trajet creent une reaction."
$doc += Paragraph "Notifications" "Heading2"
$doc += Bullet "notification_send_succeeded cote backend dit que Laravel/FCM a accepte l'envoi."
$doc += Bullet "notification_received cote mobile dit que l'app a recu un push."
$doc += Bullet "notification_displayed dit que l'app a affiche une notification locale."
$doc += Bullet "notification_opened dit que l'utilisateur a agi."
$doc += Paragraph "Monetisation" "Heading2"
$doc += Bullet "paywall_displayed -> subscription_trial_started ou subscription_purchased -> subscription_renewed/cancelled/expired."
$doc += Bullet "subscription_limit_reached et premium_action_denied signalent les moments ou la valeur gratuite touche sa limite."
$doc += Bullet "paywall_open_failed et subscription_purchase_failed servent a separer refus utilisateur et probleme technique."
$doc += Paragraph "Mise a jour forcee" "Heading2"
$doc += Bullet "app_status_checked mesure les checks de version."
$doc += Bullet "forced_update_required mesure les utilisateurs bloques par build/version minimum."
$doc += Bullet "forced_update_screen_viewed et forced_update_store_opened montrent si le blocage pousse vraiment vers le store."

$doc += Paragraph "6. Backfill historique effectue" "Heading1"
$doc += Paragraph "Un backfill Laravel a ete prepare et execute sur 180 jours. Le dry-run puis l'envoi force ont montre les volumes ci-dessous. Apres correction de POSTHOG_PROJECT_API_KEY, le backend a confirme: PostHog backfill sent." "Normal"
$doc += Table @("Item backfill", "Count", "Interpretation") $backfill
$doc += Paragraph "Important: le backfill donne de la profondeur historique aux events backend, mais il ne remplace pas les events purement mobiles comme les ecrans, les permissions ou les notifications recues." "Normal"

$doc += Paragraph "7. Gouvernance et hygiene tracking" "Heading1"
$doc += Bullet "Le backend PostHogService bloque les proprietes sensibles: email, phone, name, latitude, longitude, address, token, secret, password, payload, etc."
$doc += Bullet "Le backend utilise firebase_uid comme distinct_id quand disponible pour aligner mobile et Laravel."
$doc += Bullet "Les captures backend respectent analytics_consent=false sur les utilisateurs."
$doc += Bullet "Les events backend sont envoyes immediatement en console, utile pour le backfill, et en fin de requete HTTP en production."
$doc += Bullet "Les proprietes utilisateurs synchronisees incluent notamment tier, has_active_contact et des buckets de volumes plutot que des listes sensibles."

$doc += Paragraph "8. Ce qu'il faut ajouter plus tard" "Heading1"
$doc += Table @("Sujet", "Pourquoi", "Condition") $future
$doc += Paragraph "Priorite recommandee: attendre que la version instrumentee soit deployee et genere quelques donnees, puis creer quatre nouveaux insights: Funnel invitation complet, Sante notifications, Friction paywall, Impact forced update. Avant ce deploiement, ces insights seraient vides." "Normal"

$doc += Paragraph "9. Limites de verification" "Heading1"
$doc += Bullet "PostHog a confirme les events actuellement visibles et les insights sauvegardes, mais plusieurs nouveaux events ne peuvent pas encore etre observes avant deploiement."
$doc += Bullet "Les commandes php -l passent sur les fichiers backend touches. En revanche dart, flutter et python ne sont pas disponibles dans le PATH de ce poste, donc l'analyse Flutter et le rendu DOCX via le renderer Python de la skill peuvent etre limites."
$doc += Bullet "Les handlers FCM background peuvent tourner dans un isolate mobile separe; la mesure mobile notification_received reste best effort. Le signal serveur notification_send_succeeded/failed est donc essentiel."

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>
$($doc -join "`n")
<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>
</w:body>
</w:document>
"@

$stylesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr><w:pPr><w:spacing w:after="120" w:line="264" w:lineRule="auto"/></w:pPr></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:rPr><w:b/><w:color w:val="0B2545"/><w:sz w:val="40"/></w:rPr><w:pPr><w:spacing w:after="160"/></w:pPr></w:style>
<w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:rPr><w:color w:val="555555"/><w:sz w:val="22"/></w:rPr><w:pPr><w:spacing w:after="200"/></w:pPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:rPr><w:b/><w:color w:val="2E74B5"/><w:sz w:val="32"/></w:rPr><w:pPr><w:keepNext/><w:spacing w:before="320" w:after="160"/></w:pPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:rPr><w:b/><w:color w:val="2E74B5"/><w:sz w:val="26"/></w:rPr><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="120"/></w:pPr></w:style>
<w:style w:type="paragraph" w:styleId="Bullet"><w:name w:val="Bullet"/><w:basedOn w:val="Normal"/><w:pPr><w:ind w:left="360" w:hanging="180"/><w:spacing w:after="80"/></w:pPr><w:rPr><w:sz w:val="22"/></w:rPr></w:style>
</w:styles>
"@

$contentTypes = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
"@

$rels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
"@

$docRels = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
"@

if (Test-Path $outPath) { Remove-Item -LiteralPath $outPath -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fileStream = [System.IO.File]::Open($outPath, [System.IO.FileMode]::CreateNew)
try {
    $archive = [System.IO.Compression.ZipArchive]::new($fileStream, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        AddZipTextEntry $archive "[Content_Types].xml" $contentTypes
        AddZipTextEntry $archive "_rels/.rels" $rels
        AddZipTextEntry $archive "word/document.xml" $documentXml
        AddZipTextEntry $archive "word/styles.xml" $stylesXml
        AddZipTextEntry $archive "word/_rels/document.xml.rels" $docRels
    } finally {
        $archive.Dispose()
    }
} finally {
    $fileStream.Dispose()
}
Remove-Item -LiteralPath $tempDir -Recurse -Force

Write-Output $outPath
