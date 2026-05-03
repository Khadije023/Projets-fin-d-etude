import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class MaTrousseDeSecoursPage extends StatelessWidget {
  const MaTrousseDeSecoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'categories.protection_hygiene.title'.tr(),
        'items': [
          'categories.protection_hygiene.items.disposable_gloves'.tr(),
          'categories.protection_hygiene.items.surgical_mask'.tr(),
          'categories.protection_hygiene.items.sterile_compresses'.tr(),
          'categories.protection_hygiene.items.physiological_serum'.tr(),
          'categories.protection_hygiene.items.skin_antiseptic'.tr()
        ],
        'icon': Icons.medical_services,
      },
      {
        'title': 'categories.wound_care.title'.tr(),
        'items': [
          'categories.wound_care.items.adhesive_bandages'.tr(),
          'categories.wound_care.items.elastic_bands'.tr(),
          'categories.wound_care.items.tape'.tr(),
          'categories.wound_care.items.round_scissors'.tr(),
          'categories.wound_care.items.splinter_tweezers'.tr()
        ],
        'icon': Icons.healing,
      },
      {
        'title': 'categories.comfort_monitoring.title'.tr(),
        'items': [
          'categories.comfort_monitoring.items.thermometer'.tr(),
          'categories.comfort_monitoring.items.survival_blanket'.tr(),
          'categories.comfort_monitoring.items.instant_ice'.tr()
        ],
        'icon': Icons.bedtime,
      },
      {
        'title': 'categories.medications.title'.tr(),
        'items': [
          'categories.medications.items.paracetamol'.tr(),
          'categories.medications.items.antihistamine'.tr(),
          'categories.medications.items.anti_diarrheal'.tr(),
          'categories.medications.items.sro'.tr()
        ],
        'icon': Icons.medication,
      },
      {
        'title': 'categories.useful_documents.title'.tr(),
        'items': [
          'categories.useful_documents.items.emergency_numbers'.tr(),
          'categories.useful_documents.items.kit_instructions'.tr(),
          'categories.useful_documents.items.medical_record'.tr()
        ],
        'icon': Icons.description,
      },
    ];

    final List<Map<String, dynamic>> typesDeTrousse = [
      {
        'title': 'kit_types.baby_kit.title'.tr(),
        'items': [
          'kit_types.baby_kit.items.thermometer'.tr(),
          'kit_types.baby_kit.items.child_doliprane'.tr(),
          'kit_types.baby_kit.items.aspivenin'.tr(),
          'kit_types.baby_kit.items.arnica_gel'.tr(),
          'kit_types.baby_kit.items.cotton'.tr(),
          'kit_types.baby_kit.items.elastic_band'.tr(),
          'kit_types.baby_kit.items.fun_bandages'.tr(),
          'kit_types.baby_kit.items.physiological_serum_ampoules'.tr(),
          'kit_types.baby_kit.items.tweezers_scissors'.tr(),
          'kit_types.baby_kit.items.gentle_disinfectant'.tr(),
          'kit_types.baby_kit.items.scratch_itch_cream'.tr(),
          'kit_types.baby_kit.items.nearby_doctor_address'.tr(),
          'kit_types.baby_kit.items.rehydration_sachets'.tr(),
          'kit_types.baby_kit.items.cold_protection_cream'.tr(),
          'kit_types.baby_kit.items.sunscreen'.tr(),
          'kit_types.baby_kit.items.cooling_pack'.tr()
        ],
        'icon': Icons.child_friendly,
      },
      {
        'title': 'kit_types.home_kit.title'.tr(),
        'items': [
          'kit_types.home_kit.items.disinfectant'.tr(),
          'kit_types.home_kit.items.bandages'.tr(),
          'kit_types.home_kit.items.compresses'.tr(),
          'kit_types.home_kit.items.tape'.tr(),
          'kit_types.home_kit.items.scissors'.tr(),
          'kit_types.home_kit.items.tweezers'.tr(),
          'kit_types.home_kit.items.thermometer'.tr(),
          'kit_types.home_kit.items.painkiller'.tr(),
          'kit_types.home_kit.items.antihistamine'.tr(),
          'kit_types.home_kit.items.disposable_gloves'.tr()
        ],
        'icon': Icons.home,
      },
      {
        'title': 'kit_types.travel_kit.title'.tr(),
        'items': [
          'kit_types.travel_kit.items.personal_medications'.tr(),
          'kit_types.travel_kit.items.anti_diarrheal'.tr(),
          'kit_types.travel_kit.items.anti_nausea'.tr(),
          'kit_types.travel_kit.items.sunscreen'.tr(),
          'kit_types.travel_kit.items.mosquito_repellent'.tr(),
          'kit_types.travel_kit.items.hand_sanitizer'.tr(),
          'kit_types.travel_kit.items.blister_bandages'.tr(),
          'kit_types.travel_kit.items.oral_rehydration_solution'.tr()
        ],
        'icon': Icons.travel_explore,
      },
      {
        'title': 'kit_types.hiking_kit.title'.tr(),
        'items': [
          'kit_types.hiking_kit.items.elastic_bandages'.tr(),
          'kit_types.hiking_kit.items.special_bandages'.tr(),
          'kit_types.hiking_kit.items.disinfectant'.tr(),
          'kit_types.hiking_kit.items.emergency_whistle'.tr(),
          'kit_types.hiking_kit.items.survival_blanket'.tr(),
          'kit_types.hiking_kit.items.water_purification_tablets'.tr(),
          'kit_types.hiking_kit.items.anti_inflammatory'.tr()
        ],
        'icon': Icons.hiking,
      },
      {
        'title': 'kit_types.business_kit.title'.tr(),
        'items': [
          'kit_types.business_kit.items.standard_first_aid'.tr(),
          'kit_types.business_kit.items.hydroalcoholic_gel'.tr(),
          'kit_types.business_kit.items.defibrillator'.tr(),
          'kit_types.business_kit.items.accident_register'.tr(),
          'kit_types.business_kit.items.safety_instructions'.tr()
        ],
        'icon': Icons.business,
      },
      {
        'title': 'kit_types.construction_kit.title'.tr(),
        'items': [
          'kit_types.construction_kit.items.reinforced_first_aid'.tr(),
          'kit_types.construction_kit.items.eye_wash'.tr(),
          'kit_types.construction_kit.items.high_resistance_bandages'.tr(),
          'kit_types.construction_kit.items.splints'.tr(),
          'kit_types.construction_kit.items.tourniquet'.tr(),
          'kit_types.construction_kit.items.burn_kit'.tr()
        ],
        'icon': Icons.construction,
      },
    ];

    final List<String> conseils = [
      'storage_tips.accessible_location'.tr(),
      'storage_tips.check_expiration_dates'.tr(),
      'storage_tips.replenish_after_use'.tr(),
      'storage_tips.avoid_heat_humidity'.tr(),
      'storage_tips.adapt_to_needs'.tr(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('app_bar.title'.tr()),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.medical_services,
                        size: 80, color: Colors.redAccent),
                    const SizedBox(height: 10),
                    Text(
                      'main.title'.tr(),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'main.subtitle'.tr(),
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Text(
                'sectionss.categories'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        color: Colors.grey.shade100,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(category['icon'],
                                      color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category['title'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        category['items'].map<Widget>((item) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 2.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check,
                                                size: 16, color: Colors.green),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'sectionss.kit_types'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: typesDeTrousse.length,
                  itemBuilder: (context, index) {
                    final kit = typesDeTrousse[index];
                    return Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        color: Colors.pink.shade50,
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(kit['icon'], color: Colors.pink),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      kit['title'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: kit['items'].map<Widget>((item) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 2.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check,
                                                size: 16, color: Colors.green),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                item,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'sectionss.first_aid_info'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: Colors.lightBlue.shade50,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'info_section.title'.tr(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'info_section.minimum_necessary'.tr(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text('info_section.antiseptic'.tr(),
                            style: const TextStyle(fontSize: 14)),
                        Text('info_section.hydrogel'.tr(),
                            style: const TextStyle(fontSize: 14)),
                        Text('info_section.physiological_serum'.tr(),
                            style: const TextStyle(fontSize: 14)),
                        Text(
                          'info_section.adapt_content'.tr(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'info_section.what_is_it_for'.tr(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'info_section.react_quickly'.tr(),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text('info_section.allows_to'.tr(),
                            style: const TextStyle(fontSize: 14)),
                        Text('info_section.treat_wounds'.tr(),
                            style: const TextStyle(fontSize: 14)),
                        Text('info_section.compress_wounds'.tr(),
                            style: const TextStyle(fontSize: 14)),
                        Text('info_section.face_hypothermia'.tr(),
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'sectionss.storage_tips'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...conseils.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
