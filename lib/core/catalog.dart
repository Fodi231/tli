import 'models.dart';

const products = <Product>[
  Product('d1', 'display', 'iPhone 15 Pro', 250, 4.8),
  Product('d2', 'display', 'iPhone 13', 140, 4.6),
  Product('d3', 'display', 'Galaxy S22', 120, 4.5),
  Product('b1', 'battery', 'iPhone 14', 45, 4.6),
  Product('b2', 'battery', 'iPhone 11', 35, 4.5),
  Product('b3', 'battery', 'Galaxy S23', 40, 4.4),
  Product('c1', 'camera', 'Galaxy S23', 120, 4.7),
  Product('c2', 'camera', 'iPhone 13', 95, 4.6),
  Product('p1', 'port', 'iPad Air', 25, 4.5),
  Product('p2', 'port', 'iPhone 12', 18, 4.4),
  Product('p3', 'port', 'Pixel 7', 22, 4.3),
  Product('fd1', 'display', 'iPhone Duo', 620, 4.7),
  Product('fd2', 'display', 'Galaxy Z Fold7', 540, 4.6),
  Product('fd3', 'display', 'HUAWEI Mate XT', 850, 4.5),
  Product('fb1', 'battery', 'Galaxy Z Fold7', 85, 4.7),
  Product('fp1', 'port', 'HUAWEI Mate XT', 65, 4.6),
];

const categories = ['display', 'battery', 'camera', 'port'];

const services = <String, ServiceDef>{
  'display': ServiceDef('svc_display', 'display', 220, 420),
  'battery': ServiceDef('svc_battery', 'battery', 90, 160),
  'port': ServiceDef('svc_port', 'port', 60, 110),
  'camera': ServiceDef('svc_camera', 'camera', 170, 300),
  'diag': ServiceDef('svc_diag', null, 40, 80),
};

const devices = [
  'iPhone 11',
  'iPhone 13',
  'iPhone 15 Pro',
  'Galaxy S22',
  'Galaxy S23',
  'Pixel 7',
  'iPhone Duo',
  'Galaxy Z Fold7',
  'HUAWEI Mate XT',
  'iPad Air',
  'PlayBox 5',
];

const dealDevices = [
  DealDevice('iPhone 12', 280),
  DealDevice('iPhone 13', 420),
  DealDevice('Galaxy S22', 330),
  DealDevice('Galaxy S23', 520),
  DealDevice('Pixel 7', 300),
  DealDevice('iPad Air', 380),
  DealDevice('PlayBox 5', 430),
];

const counterpartNames = [
  'Alex',
  'Maria',
  'Kenji',
  'Olena',
  'Marco',
  'Sam',
  'Yuki',
  'Dmytro',
];

const courses = <Course>[
  Course('basics', 'c_basics', null),
  Course('display', 'c_display', 'basics'),
  Course('micro', 'c_micro', 'display'),
  Course('diag', 'c_diag', 'micro'),
];

// Real-world coordinates are used for the OpenStreetMap layer.
const cities = <City>[
  City('tokyo', ['Токио', 'Tokyo', 'Токіо'], 35.6762, 139.6503, '22°C'),
  City(
    'la',
    ['Лос-Анджелес', 'Los Angeles', 'Лос-Анджелес'],
    34.0522,
    -118.2437,
    '28°C',
  ),
  City('milan', ['Милан', 'Milan', 'Мілан'], 45.4642, 9.1900, '18°C'),
];

/// Fixed shop positions relative to the city centre (lat, lng offsets).
const shopOffsets = [
  [0.012, -0.015],
  [-0.018, 0.02],
];
