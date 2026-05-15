import 'dart:convert';
import '../services/api_service.dart';
import '../models/beneficiary_details/academic_record_model.dart';
import '../models/beneficiary_details/guardian_model.dart';
import '../models/beneficiary_details/status_model.dart';
import '../config/app_config.dart';

class BeneficiaryRepository {

  // Get all beneficiaries (for staff users)
  Future<List<Map<String, dynamic>>> getAllBeneficiaries() async {
    try {
      final response = await ApiService.get(AppConfig.beneficiaries);

      print('Get beneficiaries response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Handle Laravel API response format
        final List<dynamic> beneficiaries = data['data'] ?? data['beneficiaries'] ?? data;
        return beneficiaries.map((b) => Map<String, dynamic>.from(b)).toList();
      } else if (response.statusCode == 401) {
        print('Unauthorized - need to login again');
        return [];
      } else {
        print('Failed to get beneficiaries: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Get beneficiaries error: $e');
      return [];
    }
  }

  // Get single beneficiary with all details
  Future<Map<String, dynamic>?> getBeneficiaryDetails(int beneficiaryId) async {
    try {
      final endpoint = AppConfig.beneficiaryDetails.replaceAll('{id}', beneficiaryId.toString());
      final response = await ApiService.get(endpoint);

      print('Get beneficiary details response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['data'] ?? data['beneficiary'] ?? data;
      }
      return null;
    } catch (e) {
      print('❌ Get beneficiary details error: $e');
      return null;
    }
  }

  // Get beneficiary academic records
  Future<List<AcademicRecord>> getAcademicRecords(int beneficiaryId) async {
    try {
      final endpoint = AppConfig.beneficiaryAcademicRecords.replaceAll('{id}', beneficiaryId.toString());
      final response = await ApiService.get(endpoint);

      print('Get academic records response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> records = data['data'] ?? data['academic_records'] ?? data;
        return records.map((r) => AcademicRecord.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Get academic records error: $e');
      return [];
    }
  }

  // Get beneficiary guardians
  Future<List<Guardian>> getGuardians(int beneficiaryId) async {
    try {
      final endpoint = AppConfig.beneficiaryGuardians.replaceAll('{id}', beneficiaryId.toString());
      final response = await ApiService.get(endpoint);

      print('Get guardians response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> guardians = data['data'] ?? data['guardians'] ?? data;
        return guardians.map((g) => Guardian.fromJson(g)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Get guardians error: $e');
      return [];
    }
  }

  // Get beneficiary status history
  Future<List<BeneficiaryStatus>> getStatusHistory(int beneficiaryId) async {
    try {
      final endpoint = AppConfig.beneficiaryStatus.replaceAll('{id}', beneficiaryId.toString());
      final response = await ApiService.get(endpoint);

      print('Get status history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> statuses = data['data'] ?? data['statuses'] ?? data;
        return statuses.map((s) => BeneficiaryStatus.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Get status history error: $e');
      return [];
    }
  }

  // Create new beneficiary (for staff users)
  Future<Map<String, dynamic>?> createBeneficiary(Map<String, dynamic> beneficiaryData) async {
    try {
      final response = await ApiService.post(AppConfig.beneficiaries, beneficiaryData);

      print('Create beneficiary response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['data'] ?? data['beneficiary'] ?? data;
      }
      return null;
    } catch (e) {
      print('❌ Create beneficiary error: $e');
      return null;
    }
  }

  // Update beneficiary
  Future<Map<String, dynamic>?> updateBeneficiary(int beneficiaryId, Map<String, dynamic> beneficiaryData) async {
    try {
      final endpoint = AppConfig.beneficiaryDetails.replaceAll('{id}', beneficiaryId.toString());
      final response = await ApiService.put(endpoint, beneficiaryData);

      print('Update beneficiary response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['data'] ?? data['beneficiary'] ?? data;
      }
      return null;
    } catch (e) {
      print('❌ Update beneficiary error: $e');
      return null;
    }
  }

  // Delete beneficiary
  Future<bool> deleteBeneficiary(int beneficiaryId) async {
    try {
      final endpoint = AppConfig.beneficiaryDetails.replaceAll('{id}', beneficiaryId.toString());
      final response = await ApiService.delete(endpoint);

      print('Delete beneficiary response: ${response.statusCode}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Delete beneficiary error: $e');
      return false;
    }
  }
}