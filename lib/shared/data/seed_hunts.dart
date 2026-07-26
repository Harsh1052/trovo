import '../models/checkpoint_model.dart';
import '../models/hunt_model.dart';

/// Pre-populated seed hunts and checkpoints for instant offline/initial launch.
abstract final class SeedHunts {
  static final List<HuntModel> hunts = [
    HuntModel(
      huntId: 'cubbon_park_emerald',
      title: 'The Emerald of Cubbon Park',
      description:
          "Embark on an urban adventure through Bengaluru's lush green heart. Uncover ancient bamboo groves, red Greco-Roman architecture, royal statues, and secret bandstands hidden within 300 acres of botanical paradise.",
      city: 'Bengaluru',
      gardenName: 'Cubbon Park',
      difficulty: HuntDifficulty.medium,
      durationMinutes: 60,
      checkpointCount: 5,
      isFree: true,
      price: 0,
      coverImageUrl: 'assets/images/cover_cubbon_park.png',
      startLatitude: 12.976300,
      startLongitude: 77.592900,
      isActive: true,
      createdAt: DateTime.parse('2026-07-25T12:00:00.000Z'),
    ),
    HuntModel(
      huntId: 'panchvati_garden',
      title: 'Panchvati Heritage Trail',
      description:
          "Follow the footsteps of the Ramayana along the sacred ghats and temples of ancient Panchvati. Solve eight riddles hidden across Nashik's most storied quarter — from the holy waters of Ramkund to the arched bridge above the Godavari.",
      city: 'Nashik',
      gardenName: 'Panchvati',
      difficulty: HuntDifficulty.easy,
      durationMinutes: 90,
      checkpointCount: 8,
      isFree: true,
      price: 0,
      coverImageUrl: 'assets/images/cover_panchvati.png',
      startLatitude: 20.003610,
      startLongitude: 73.776840,
      isActive: true,
      createdAt: DateTime.parse('2024-10-01T08:00:00.000Z'),
    ),
    HuntModel(
      huntId: 'sula_vineyards',
      title: 'Sula Vintage Code',
      description:
          "Uncover the secrets of Nashik's wine country across the sun-drenched vineyards and cellar rooms of Sula. From barrel to bottle, from gate to hilltop — can you crack the vintage code before the sun sets over Gangapur Dam?",
      city: 'Nashik',
      gardenName: 'Sula Vineyards',
      difficulty: HuntDifficulty.medium,
      durationMinutes: 75,
      checkpointCount: 6,
      isFree: false,
      price: 29900,
      coverImageUrl: 'assets/images/cover_sula.png',
      startLatitude: 20.006500,
      startLongitude: 73.698000,
      isActive: true,
      createdAt: DateTime.parse('2024-10-05T09:00:00.000Z'),
    ),
  ];

  static final Map<String, List<CheckpointModel>> checkpoints = {
    'cubbon_park_emerald': [
      CheckpointModel(
        checkpointId: 'cpe_cp_01',
        huntId: 'cubbon_park_emerald',
        orderIndex: 0,
        clueText:
            'I am a giant bamboo grove planted in 1870. When the breeze blows through my hollow green stems, I rustle like a forest stream. What type of plant am I?',
        hintText:
            'Pandas love to eat this plant. It is the fastest-growing woody plant in the world.',
        latitude: 12.976300,
        longitude: 77.592900,
        type: CheckpointType.clue,
        answer: 'bamboo',
        unlockRadius: 20,
        funFact:
            "Cubbon Park's bamboo groves date back over 150 years and house over 6,000 species of flora.",
      ),
      CheckpointModel(
        checkpointId: 'cpe_cp_02',
        huntId: 'cubbon_park_emerald',
        orderIndex: 1,
        clueText:
            'Stand near the striking red Greco-Roman facade of the Seshadri Iyer Memorial Hall (State Central Library). Take a victory photo near the stone archway!',
        hintText:
            'Look for the iconic bright red heritage building housing thousands of historic books.',
        latitude: 12.975400,
        longitude: 77.591800,
        type: CheckpointType.photoTask,
        answer: null,
        unlockRadius: 25,
        funFact:
            'The State Central Library inside Seshadri Iyer Memorial Hall holds over 300,000 rare books, including braille editions.',
      ),
      CheckpointModel(
        checkpointId: 'cpe_cp_03',
        huntId: 'cubbon_park_emerald',
        orderIndex: 2,
        clueText:
            'Guarded by silver oak trees, I am a queen sculpted in white marble who ruled an empire where the sun never set. What is her name?',
        hintText:
            'She was the Queen of the United Kingdom and Empress of India until 1901.',
        latitude: 12.977100,
        longitude: 77.594200,
        type: CheckpointType.clue,
        answer: 'victoria',
        unlockRadius: 20,
        funFact:
            'The Victoria Statue at Cubbon Park was unveiled in 1906 and is one of the few surviving British-era marble statues in India.',
      ),
      CheckpointModel(
        checkpointId: 'cpe_cp_04',
        huntId: 'cubbon_park_emerald',
        orderIndex: 3,
        clueText:
            'I am an octagonal red-brick structure with cast-iron pillars. Royal military brass bands played concerts here every Sunday evening in the 19th century. What am I called?',
        hintText: 'Eight-sided roofed structure for live musical performances.',
        latitude: 12.974800,
        longitude: 77.593500,
        type: CheckpointType.clue,
        answer: 'bandstand',
        unlockRadius: 20,
        funFact:
            'Built in 1870, the Cubbon Park Bandstand was the cultural heart of British Bangalore\'s social life.',
      ),
      CheckpointModel(
        checkpointId: 'cpe_cp_05',
        huntId: 'cubbon_park_emerald',
        orderIndex: 4,
        clueText:
            'Reach the lotus fountain pond surrounded by Royal Palms. Take a photo of the water lily blossoms reflecting the blue sky to complete your quest!',
        hintText:
            'Located near the rose garden walkway on the eastern side of the park.',
        latitude: 12.973900,
        longitude: 77.595100,
        type: CheckpointType.photoTask,
        answer: null,
        unlockRadius: 30,
        funFact:
            "Cubbon Park reduces Bengaluru's central urban heat island temperature by up to 3°C!",
      ),
    ],
    'panchvati_garden': [
      CheckpointModel(
        checkpointId: 'pg_cp_01',
        huntId: 'panchvati_garden',
        orderIndex: 0,
        clueText:
            'I am a sacred pool carved by the Godavari herself, where pilgrims immerse the ashes of loved ones to grant them moksha. What river feeds me?',
        hintText:
            'Her name means "giver of cows" in Sanskrit. She is called the Ganges of the South.',
        latitude: 20.003610,
        longitude: 73.776840,
        type: CheckpointType.clue,
        answer: 'godavari',
        unlockRadius: 20,
        funFact:
            'Ramkund never dries up even in Nashik\'s harshest summers.',
      ),
    ],
    'sula_vineyards': [
      CheckpointModel(
        checkpointId: 'sv_cp_01',
        huntId: 'sula_vineyards',
        orderIndex: 0,
        clueText:
            'Before the vines, before the barrel, there was one man\'s dream and one valley\'s volcanic soil. What is the founder\'s first name?',
        hintText: 'His surname is Samant.',
        latitude: 20.006500,
        longitude: 73.698000,
        type: CheckpointType.clue,
        answer: 'rajeev',
        unlockRadius: 20,
        funFact: 'Rajeev Samant founded Sula Vineyards in 1999.',
      ),
    ],
  };
}
