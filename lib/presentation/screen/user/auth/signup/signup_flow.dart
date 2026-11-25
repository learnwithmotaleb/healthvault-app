import 'package:get/get.dart';

import '../../../provider/doctor_identification/controller/doctor_indentification_controller.dart';
import '../../../provider/medical_license/controller/medical_license_controller.dart';
import '../../../provider/passport_identification/controller/passport_identification_controller.dart';
import '../../../provider/pharmacy_identification/controller/pharmacy_identification_controller.dart';
import '../Identification/controller/identification_controller.dart';
import '../registaration/controller/registration_controller.dart';
import 'controller/signup_controller.dart';

/// The sign-up screens share data across several steps. Their controllers are
/// kept alive (so going back never clears typed fields) until the user either
/// finishes registration or leaves the Sign Up screen.
class SignupFlow {
  static void clear() {
    void del<T>() {
      if (Get.isRegistered<T>()) Get.delete<T>(force: true);
    }

    del<IdentificationController>();
    del<RegistrationController>();
    del<PassportIdentificationController>();
    del<MedicalLicenseController>();
    del<DoctorIdentificationController>();
    del<PharmacyIdentificationController>();
    del<SignupController>();
  }
}
