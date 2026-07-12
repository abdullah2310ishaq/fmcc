import 'package:doctor_app/src/features/patients/patient_api_models.dart';

void main() {
  final samples = <dynamic>[
    [
      {
        'id': 5,
        'instructionName':
            'Limit sodium (salt) intake to less than 1,500 mg per day.',
      },
      {
        'id': 6,
        'instructionName':
            'Engage in at least 30 minutes of moderate aerobic exercise.',
      },
    ],
    {
      'data': [
        {'id': 5, 'instructionName': 'A'},
        {'id': 6, 'instructionName': 'B'},
      ],
    },
    '[{"id":5,"instructionName":"Limit sodium"},{"id":6,"instructionName":"Exercise"}]',
  ];

  for (var i = 0; i < samples.length; i++) {
    final parsed = parseCounsellingInstructionsList(samples[i]);
    print(
        'sample $i -> ${parsed.length}: ${parsed.map((e) => e.instructionName).join(' | ')}');
  }
}
