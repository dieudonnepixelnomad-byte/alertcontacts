import 'package:flutter/foundation.dart';

/// Modèle léger pour stocker les infos saisies durant le wizard
class UserSetupData {
  String firstName;
  String ageRange; // "<18", "18-35", "36-60", "60+"
  String gender; // "female", "male", "other", "prefer_not_to_say"
  String primaryGoal; // enfants, proche_age, maison_trajets, moi_meme, collaborateurs
  String experienceLevel; // "experienced", "first_time"

  UserSetupData({
    this.firstName = 'Moi',
    this.ageRange = '18-35',
    this.gender = 'prefer_not_to_say',
    this.primaryGoal = 'moi_meme',
    this.experienceLevel = 'first_time',
  });

  Map<String, dynamic> toJson() => {
        'first_name': firstName.isEmpty ? 'Utilisateur' : firstName,
        'age_range': ageRange,
        'gender': gender,
        'primary_goal': primaryGoal,
        'experience_level': experienceLevel,
      };
}

class UserSetupProvider extends ChangeNotifier {
  final UserSetupData data = UserSetupData();
  int currentStep = 0; // 0..2
  bool isSubmitting = false;

  void setFirstName(String value) {
    data.firstName = value;
    notifyListeners();
  }

  void setAgeRange(String value) {
    data.ageRange = value;
    notifyListeners();
  }

  void setGender(String value) {
    data.gender = value;
    notifyListeners();
  }

  void setPrimaryGoal(String value) {
    data.primaryGoal = value;
    notifyListeners();
  }

  void setExperienceLevel(String value) {
    data.experienceLevel = value;
    notifyListeners();
  }

  void nextStep() {
    if (currentStep < 2) {
      currentStep += 1;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep -= 1;
      notifyListeners();
    }
  }

  void setSubmitting(bool submitting) {
    isSubmitting = submitting;
    notifyListeners();
  }
}