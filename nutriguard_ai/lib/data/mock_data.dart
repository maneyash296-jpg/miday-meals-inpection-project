class MockData {
  // KPI Data
  static const teacherKpis = {
    'studentsPresent': 182,
    'mealsServed': 176,
    'compliance': 94,
    'foodWaste': 6.2,
  };

  static const principalKpis = {
    'students': 524,
    'mealsToday': 508,
    'compliance': 94,
    'foodWaste': 5.8,
    'rationSupply': 92,
  };

  static const rationShopKpis = {
    'currentStock': 4850,
    'schoolsSupplied': 18,
    'pendingDeliveries': 3,
    'stockAccuracy': 96,
    'wastage': 2.4,
    'riskScore': 18,
  };

  static const districtKpis = {
    'schools': 248,
    'rationShops': 42,
    'mealsMonitored': 18450,
    'resourceWaste': 4.8,
    'supplyCompliance': 93,
    'highRiskSchools': 17,
    'highRiskShops': 5,
  };

  // Lists
  static const recentActivity = [
    {'time': '10:30 AM', 'event': 'Meal captured', 'status': 'completed'},
    {'time': '10:34 AM', 'event': 'AI analysis completed', 'status': 'completed'},
    {'time': '10:40 AM', 'event': 'Inventory updated', 'status': 'completed'},
  ];

  static const teacherAlerts = [
    {'title': 'Low Dal Stock', 'description': 'Only 48 kg remaining', 'type': 'warning'},
    {'title': 'Meal Compliance Warning', 'description': 'Vegetable quantity appears low', 'type': 'critical'},
    {'title': 'Today\'s Meal', 'description': 'Successfully verified', 'type': 'info'},
  ];

  static const inventory = [
    {'item': 'Rice', 'quantity': 185, 'unit': 'kg', 'status': 'Healthy'},
    {'item': 'Dal', 'quantity': 48, 'unit': 'kg', 'status': 'Low Stock'},
    {'item': 'Oil', 'quantity': 12, 'unit': 'L', 'status': 'Healthy'},
  ];

  static const aiAnalysisResults = [
    {'item': 'Rice', 'qty': '10.5 kg', 'confidence': '92%', 'status': 'success'},
    {'item': 'Dal', 'qty': '4.2 kg', 'confidence': '89%', 'status': 'success'},
    {'item': 'Vegetable', 'qty': '3.8 kg', 'confidence': '86%', 'status': 'warning'},
    {'item': 'Fruit', 'qty': '176 portions', 'confidence': '91%', 'status': 'success'},
  ];

  static const wasteCategories = [
    {'item': 'Rice', 'qty': 2.4, 'unit': 'kg'},
    {'item': 'Dal', 'qty': 1.1, 'unit': 'kg'},
    {'item': 'Vegetables', 'qty': 2.0, 'unit': 'kg'},
    {'item': 'Other', 'qty': 0.7, 'unit': 'kg'},
  ];
}
