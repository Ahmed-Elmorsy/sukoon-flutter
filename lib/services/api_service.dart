import 'dart:typed_data';

import 'api_service/auth_api.dart';
import 'api_service/profile_api.dart';
import 'api_service/apartments_api.dart';
import 'api_service/contracts_api.dart';
import 'api_service/admin_api.dart';
import 'api_service/notifications_api.dart';
import 'api_service/payments_api.dart';

class ApiService {
  // ── AUTHENTICATION & ONBOARDING ──────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String phone,
    required String email,
    required String password,
    required String gender,
    required String role,
  }) =>
      AuthApiService.register(
        phone: phone,
        email: email,
        password: password,
        gender: gender,
        role: role,
      );

  static Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) =>
      AuthApiService.login(login: login, password: password);

  static Future<Map<String, dynamic>> getMe(String token) =>
      AuthApiService.getMe(token);

  static Future<void> logout(String token) => AuthApiService.logout(token);

  static Future<Map<String, dynamic>> forgotPassword(String login) =>
      AuthApiService.forgotPassword(login);

  static Future<Map<String, dynamic>> resetPassword({
    required String login,
    required String code,
    required String password,
  }) =>
      AuthApiService.resetPassword(
        login: login,
        code: code,
        password: password,
      );

  static Future<Map<String, dynamic>> resendOtp(String emailOrPhone) =>
      AuthApiService.resendOtp(emailOrPhone);

  static Future<Map<String, dynamic>> verifyOtp(
          String emailOrPhone, String code) =>
      AuthApiService.verifyOtp(emailOrPhone, code);

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String password,
  }) =>
      AuthApiService.changePassword(
        token: token,
        currentPassword: currentPassword,
        password: password,
      );

  static Future<Map<String, dynamic>> refreshToken(String token) =>
      AuthApiService.refreshToken(token);

  static Future<void> saveFcmToken(String token, String fcmToken) =>
      AuthApiService.saveFcmToken(token, fcmToken);

  // ── PROFILE & ONBOARDING ─────────────────────────────────────

  static Future<Map<String, dynamic>> saveRentalProfile({
    required String token,
    required String type,
    String? university,
    String? faculty,
    String? company,
    String? jobTitle,
  }) =>
      ProfileApiService.saveRentalProfile(
        token: token,
        type: type,
        university: university,
        faculty: faculty,
        company: company,
        jobTitle: jobTitle,
      );

  static Future<Map<String, dynamic>> saveUserProfile({
    required String token,
    required String firstName,
    String? middleName,
    required String lastName,
    required int age,
    required String country,
    required String city,
    Uint8List? photoBytes,
    String? photoName,
  }) =>
      ProfileApiService.saveUserProfile(
        token: token,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        age: age,
        country: country,
        city: city,
        photoBytes: photoBytes,
        photoName: photoName,
      );

  static Future<Map<String, dynamic>> saveSponsorProfile({
    required String token,
    required String companyName,
    required String companyDetails,
    String? targetAudience,
  }) =>
      ProfileApiService.saveSponsorProfile(
        token: token,
        companyName: companyName,
        companyDetails: companyDetails,
        targetAudience: targetAudience,
      );

  static Future<Map<String, dynamic>> uploadIdentityDocuments({
    required String token,
    required List<Map<String, dynamic>> documents,
  }) =>
      ProfileApiService.uploadIdentityDocuments(
        token: token,
        documents: documents,
      );

  static Future<Map<String, dynamic>> saveOcrData(
          String token, Map<String, dynamic> ocrData) =>
      ProfileApiService.saveOcrData(token, ocrData);

  // ── APARTMENTS ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> getApartments(String token) =>
      ApartmentsApiService.getApartments(token);

  static Future<Map<String, dynamic>> getApartment(String token, int id) =>
      ApartmentsApiService.getApartment(token, id);

  static Future<Map<String, dynamic>> createApartment({
    required String token,
    required Map<String, String> fields,
    Uint8List? documentBytes,
    String? documentName,
    List<Uint8List>? photoBytesList,
    List<String>? photoNamesList,
  }) =>
      ApartmentsApiService.createApartment(
        token: token,
        fields: fields,
        documentBytes: documentBytes,
        documentName: documentName,
        photoBytesList: photoBytesList,
        photoNamesList: photoNamesList,
      );

  static Future<Map<String, dynamic>> updateApartment({
    required String token,
    required int id,
    required Map<String, String> fields,
    Uint8List? documentBytes,
    String? documentName,
    List<Uint8List>? photoBytesList,
    List<String>? photoNamesList,
    List<String>? deletePhotos,
  }) =>
      ApartmentsApiService.updateApartment(
        token: token,
        id: id,
        fields: fields,
        documentBytes: documentBytes,
        documentName: documentName,
        photoBytesList: photoBytesList,
        photoNamesList: photoNamesList,
        deletePhotos: deletePhotos,
      );

  static Future<Map<String, dynamic>> deleteApartment(String token, int id) =>
      ApartmentsApiService.deleteApartment(token, id);

  static Future<Map<String, dynamic>> joinApartment(String token, int id) =>
      ApartmentsApiService.joinApartment(token, id);

  static Future<Map<String, dynamic>> leaveApartment(String token, int id) =>
      ApartmentsApiService.leaveApartment(token, id);

  static Future<Map<String, dynamic>> getApartmentMembers(
          String token, int apartmentId) =>
      ApartmentsApiService.getApartmentMembers(token, apartmentId);

  static Future<Map<String, dynamic>> removeApartmentMember(
          String token, int apartmentId, int userId) =>
      ApartmentsApiService.removeApartmentMember(token, apartmentId, userId);

  static Future<Map<String, dynamic>> addApartmentMember(
          String token, int apartmentId, String email) =>
      ApartmentsApiService.addApartmentMember(token, apartmentId, email);

  // ── CONTRACTS ────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getContracts(String token) =>
      ContractsApiService.getContracts(token);

  static Future<Map<String, dynamic>> getOwnerContracts(String token) =>
      ContractsApiService.getOwnerContracts(token);

  static Future<Map<String, dynamic>> getOwners(String token) =>
      ContractsApiService.getOwners(token);

  static Future<Map<String, dynamic>> createContract({
    required String token,
    required int apartmentId,
    required Uint8List documentBytes,
    required String fileName,
  }) =>
      ContractsApiService.createContract(
        token: token,
        apartmentId: apartmentId,
        documentBytes: documentBytes,
        fileName: fileName,
      );

  static Future<Map<String, dynamic>> acceptContract(String token, int id) =>
      ContractsApiService.acceptContract(token, id);

  static Future<Map<String, dynamic>> refuseContract(
          String token, int id, String reason) =>
      ContractsApiService.refuseContract(token, id, reason);

  static Future<Map<String, dynamic>> getAdminContracts(String token) =>
      ContractsApiService.getAdminContracts(token);

  static Future<Map<String, dynamic>> getContract(String token, int id) =>
      ContractsApiService.getContract(token, id);

  static Future<Map<String, dynamic>> updateContract({
    required String token,
    required int id,
    required Uint8List documentBytes,
    required String fileName,
    String type = 'contract',
  }) =>
      ContractsApiService.updateContract(
        token: token,
        id: id,
        documentBytes: documentBytes,
        fileName: fileName,
        type: type,
      );

  static Future<Map<String, dynamic>> deleteContract(String token, int id) =>
      ContractsApiService.deleteContract(token, id);

  static Future<Map<String, dynamic>> getMyContract(
          String token, int apartmentId) =>
      ContractsApiService.getMyContract(token, apartmentId);

  static Future<Map<String, dynamic>> deleteMyContract(
          String token, int apartmentId) =>
      ContractsApiService.deleteMyContract(token, apartmentId);

  // ── ADMIN USER/APARTMENT MANAGEMENT ──────────────────────────

  static Future<Map<String, dynamic>> getUsers(String token) =>
      AdminApiService.getUsers(token);

  static Future<Map<String, dynamic>> createUser(
          String token, Map<String, dynamic> data) =>
      AdminApiService.createUser(token, data);

  static Future<Map<String, dynamic>> updateUser(
          String token, int id, Map<String, dynamic> data) =>
      AdminApiService.updateUser(token, id, data);

  static Future<Map<String, dynamic>> deleteUser(String token, int id) =>
      AdminApiService.deleteUser(token, id);

  static Future<Map<String, dynamic>> promoteToAdmin(String token, int id) =>
      AdminApiService.promoteToAdmin(token, id);

  static Future<Map<String, dynamic>> demoteFromAdmin(String token, int id) =>
      AdminApiService.demoteFromAdmin(token, id);

  static Future<Map<String, dynamic>> verifyApartment(String token, int id) =>
      AdminApiService.verifyApartment(token, id);

  static Future<Map<String, dynamic>> refuseApartment(String token, int id,
          {String? reason}) =>
      AdminApiService.refuseApartment(token, id, reason: reason);

  static Future<Map<String, dynamic>> verifyIdentityDocument(
          String token, int id) =>
      AdminApiService.verifyIdentityDocument(token, id);

  static Future<Map<String, dynamic>> rejectIdentityDocument(
          String token, int id, String reason) =>
      AdminApiService.rejectIdentityDocument(token, id, reason);

  static Future<Map<String, dynamic>> verifyApartmentDocument(
          String token, int id) =>
      AdminApiService.verifyApartmentDocument(token, id);

  static Future<Map<String, dynamic>> rejectApartmentDocument(
          String token, int id, String reason) =>
      AdminApiService.rejectApartmentDocument(token, id, reason);

  static Future<Map<String, dynamic>> verifyTenantContract(
          String token, int id) =>
      AdminApiService.verifyTenantContract(token, id);

  static Future<Map<String, dynamic>> rejectTenantContract(
          String token, int id, String reason) =>
      AdminApiService.rejectTenantContract(token, id, reason);

  static Future<Map<String, dynamic>> getApartmentModerationDetails(
          String token, int id) =>
      AdminApiService.getApartmentModerationDetails(token, id);


  // ── NOTIFICATIONS ────────────────────────────────────────────

  static Future<Map<String, dynamic>> getNotifications(String token) =>
      NotificationsApiService.getNotifications(token);

  static Future<Map<String, dynamic>> markNotificationRead(
          String token, dynamic id) =>
      NotificationsApiService.markNotificationRead(token, id);

  static Future<Map<String, dynamic>> markAllNotificationsRead(String token) =>
      NotificationsApiService.markAllNotificationsRead(token);

  static Future<Map<String, dynamic>> deleteAllNotifications(String token) =>
      NotificationsApiService.deleteAllNotifications(token);

  // ── PAYMENTS ─────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPaymentOrders(String token) =>
      PaymentsApiService.getPaymentOrders(token);

  static Future<Map<String, dynamic>> getPaymentOrder(String token, int id) =>
      PaymentsApiService.getPaymentOrder(token, id);

  static Future<Map<String, dynamic>> getTransactions(String token) =>
      PaymentsApiService.getTransactions(token);

  static Future<Map<String, dynamic>> submitRefundRequest(
          String token, int paymentOrderId, String reason) =>
      PaymentsApiService.submitRefundRequest(token, paymentOrderId, reason);

  static Future<Map<String, dynamic>> getRefundRequests(String token) =>
      PaymentsApiService.getRefundRequests(token);

  static Future<Map<String, dynamic>> approveRefund(String token, int id) =>
      PaymentsApiService.approveRefund(token, id);

  static Future<Map<String, dynamic>> rejectRefund(
          String token, int id, String reason) =>
      PaymentsApiService.rejectRefund(token, id, reason);

  static Future<Map<String, dynamic>> retryPaymentLink(
          String token, int orderId) =>
      PaymentsApiService.retryPaymentLink(token, orderId);

  static Future<Map<String, dynamic>> triggerPaymobWebhook({
    required String hmac,
    required Map<String, dynamic> payload,
  }) =>
      PaymentsApiService.triggerPaymobWebhook(hmac, payload);

  // ── OWNER & TENANT PROFILE EXTENSIONS ────────────────────────
  static Future<Map<String, dynamic>> updatePayoutInfo({
    required String token,
    String? payoutInfo,
    String? payoutType,
    String? payoutNumber,
  }) =>
      ProfileApiService.updatePayoutInfo(
        token: token,
        payoutInfo: payoutInfo,
        payoutType: payoutType,
        payoutNumber: payoutNumber,
      );

  static Future<Map<String, dynamic>> uploadOwnerIdentityDocument({
    required String token,
    required String type,
    required String documentNumber,
    required List<int> fileBytes,
    required String fileName,
  }) =>
      ProfileApiService.uploadOwnerIdentityDocument(
        token: token,
        type: type,
        documentNumber: documentNumber,
        fileBytes: fileBytes,
        fileName: fileName,
      );

  static Future<Map<String, dynamic>> uploadTenantIdentityDocument({
    required String token,
    required String type,
    required String documentNumber,
    required List<int> fileBytes,
    required String fileName,
  }) =>
      ProfileApiService.uploadTenantIdentityDocument(
        token: token,
        type: type,
        documentNumber: documentNumber,
        fileBytes: fileBytes,
        fileName: fileName,
      );

  static Future<Map<String, dynamic>> uploadTenantContract({
    required String token,
    required List<int> fileBytes,
    required String fileName,
  }) =>
      ProfileApiService.uploadTenantContract(
        token: token,
        fileBytes: fileBytes,
        fileName: fileName,
      );

  static Future<Map<String, dynamic>> getTenantPaymentStatus(String token) =>
      ProfileApiService.getTenantPaymentStatus(token);

  static Future<Map<String, dynamic>> requestTenantRefund(String token) =>
      ProfileApiService.requestTenantRefund(token);
}
