## Objectif
- Mettre en place une tâche planifiée qui redémarre tous les workers de jobs toutes les 5 minutes.

## Choix technique
- Utiliser les commandes Artisan prévues par Laravel:
  - `queue:restart` pour redémarrer tous les workers de la queue (recommandé, natif Laravel).
  - Si vous utilisez Horizon: `horizon:terminate` pour arrêter proprement Horizon afin qu’il soit relancé par votre superviseur (Supervisor/systemd).

## Implémentation dans Laravel
1. Ouvrir `app/Console/Kernel.php`.
2. Dans la méthode `schedule`, ajouter:
```php
use Illuminate\Console\Scheduling\Schedule;

protected function schedule(Schedule $schedule)
{
    $schedule->command('queue:restart')
        ->everyFiveMinutes()
        ->withoutOverlapping()
        ->onOneServer();
    // Si Horizon est utilisé:
    // $schedule->command('horizon:terminate')
    //     ->everyFiveMinutes()
    //     ->withoutOverlapping()
    //     ->onOneServer();
}
```

## Cron serveur (obligatoire)
- Ajouter une entrée cron pour exécuter le scheduler Laravel chaque minute:
```
* * * * * cd /chemin/vers/alertcontacts-admin && php artisan schedule:run >> /dev/null 2>&1
```
- Si Docker, prévoir un conteneur Cron dédié ou utiliser le mécanisme du provider d’infra.

## Pré‑requis
- Les workers doivent être lancés en mode daemon via `php artisan queue:work` (supervisés par Supervisor/systemd) ou via Laravel Horizon.
- Redis disponible pour `onOneServer()` (lock distribué), sinon retirer `onOneServer()`.

## Validation
- Vérifier la planification: `php artisan schedule:list`.
- Tester manuellement: `php artisan schedule:run --verbose` et observer les logs (`storage/logs/laravel.log`) ou le dashboard Horizon.
- Confirmer que les workers se relancent (timestamp de cache de `queue:restart` mis à jour et prise en compte après le job courant).

## Notes
- `queue:restart` n’interrompt pas un job en cours; le redémarrage se fait avant le prochain job.
- Avec Horizon, `horizon:terminate` nécessite que le superviseur relance le process (Supervisor/systemd).

Souhaitez‑vous que je l’implémente avec `queue:restart` par défaut et `horizon:terminate` si Horizon est présent dans `alertcontacts-admin` ?