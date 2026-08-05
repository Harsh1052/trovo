import '../models/checkpoint_model.dart';
import '../models/hunt_model.dart';

/// Pre-populated seed hunts and checkpoints for instant offline/initial launch.
abstract final class SeedHunts {
  static final List<HuntModel> hunts = [
    HuntModel(
      huntId: 'surat_diamond_heist',
      title: 'The Royal Diamond Heist of Surat',
      description:
          "In 1670, a legendary blue diamond disappeared from the royal vaults along the Tapi River. Solve 5 encrypted merchant ciphers hidden across Sarthana's lush botanical gardens and riverwalk to unlock the royal vault!",
      city: 'Surat',
      gardenName: 'Sarthana Nature Park & Riverwalk',
      difficulty: HuntDifficulty.medium,
      durationMinutes: 60,
      checkpointCount: 5,
      isFree: true,
      price: 0,
      coverImageUrl: 'assets/images/cover_surat.png',
      startLatitude: 21.292475,
      startLongitude: 72.900636,
      isActive: true,
      createdAt: DateTime.parse('2026-07-26T15:00:00.000Z'),
    ),
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
    'surat_diamond_heist': [
      CheckpointModel(
        checkpointId: 'sdh_cp_01',
        huntId: 'surat_diamond_heist',
        orderIndex: 0,
        clueText:
            "Welcome, Detective! In 1670, the royal vault keeper left an encrypted parchment before the blue diamond vanished: 'Where the cool Tapi breeze meets Sarthana's gates, look for the city's crown jewel. 9 out of 10 of these sparkling gems in the world are cut and polished right here in Surat. What gemstone am I?'",
        hintText:
            'It is pure carbon formed under deep mantle pressure. Hardest natural mineral on Earth.',
        latitude: 21.292475,
        longitude: 72.900636,
        type: CheckpointType.clue,
        answer: 'diamond',
        unlockRadius: 20,
        funFact:
            'Surat processes 9 out of every 10 diamonds set in jewelry globally! Over 800,000 artisans work in Surat\'s Varachha & Katargam diamond hubs.',
        imageUrl: 'https://iili.io/CeP1QSf.jpg',
      ),
      CheckpointModel(
        checkpointId: 'sdh_cp_02',
        huntId: 'surat_diamond_heist',
        orderIndex: 1,
        clueText:
            "The parchment leads under the ancient Banyan Canopy! The 17th-century merchant message reads: 'Under the spreading banyan roots, the vault key bearer hid the first secret chest.' Walk beneath the royal banyan trees, look up at the green canopy, and take a victory photo!",
        hintText:
            'Follow the main shaded pathway 50 meters north of the main entrance.',
        latitude: 21.292900,
        longitude: 72.901100,
        type: CheckpointType.photoTask,
        answer: null,
        unlockRadius: 25,
        funFact:
            'Banyan trees (Ficus benghalensis) can live for over 500 years! Sarthana Nature Park spans over 81 acres of rich flora, serving as Surat\'s green lung.',
        imageUrl: 'https://iili.io/CePEes9.jpg',
        targetText: 'BANYAN',
      ),
      CheckpointModel(
        checkpointId: 'sdh_cp_03',
        huntId: 'surat_diamond_heist',
        orderIndex: 2,
        clueText:
            "Standing on the riverbank where 17th-century Dutch & Mughal galleons once loaded gold and spices. The merchant's diary reads: 'My ship set sail on the sun-daughter river that carves through Surat into the Gulf of Khambhat.' What sacred river am I?",
        hintText:
            'Her name starts with T. Ancient texts say she is Tapti, the daughter of Surya (the Sun God).',
        latitude: 21.291800,
        longitude: 72.900100,
        type: CheckpointType.clue,
        answer: 'tapi',
        unlockRadius: 20,
        funFact:
            'The Tapi river flows 724 km from Satpura Range to the Arabian Sea. In the 1600s, Surat was India\'s busiest international port along the Tapi!',
        imageUrl: 'https://iili.io/CePESUb.jpg',
      ),
      CheckpointModel(
        checkpointId: 'sdh_cp_04',
        huntId: 'surat_diamond_heist',
        orderIndex: 3,
        clueText:
            "You are near the old merchant guild marker. The cipher reveals: 'To open the royal vault, the master goldsmiths forged a key from the yellow metal that never rusts nor tarnishes—prized by Mughal emperors and trade fleets alike.' What metal is it?",
        hintText:
            'Chemical element Au (Atomic number 79). Yellow precious bullion metal.',
        latitude: 21.293200,
        longitude: 72.901500,
        type: CheckpointType.clue,
        answer: 'gold',
        unlockRadius: 20,
        funFact:
            'In 1670, Surat\'s bullion markets traded tons of gold coins, silver rupees, and zari gold thread with merchants from Arabia and Europe!',
        imageUrl: 'https://iili.io/CePG2st.jpg',
      ),
      CheckpointModel(
        checkpointId: 'sdh_cp_05',
        huntId: 'surat_diamond_heist',
        orderIndex: 4,
        clueText:
            "CONGRATULATIONS, CHIEF DETECTIVE! You have reached the central Sarthana lookout point above the Tapi waters! The royal diamond vault is unlocked! Take your final victory photo holding your key high in the air to recover the lost Royal Diamond of Surat!",
        hintText:
            'Stand at the central elevated lookout pavilion in Sarthana.',
        latitude: 21.292500,
        longitude: 72.900800,
        type: CheckpointType.photoTask,
        answer: null,
        unlockRadius: 30,
        funFact:
            'Quest Completed! You recovered the 1670 Royal Diamond of Surat, earned 500 XP, and unlocked the Master Treasure Hunter Trophy!',
        imageUrl: 'https://iili.io/CePGC7f.jpg',
        targetText: 'SURAT',
      ),
    ],
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
        imageUrl: 'assets/images/cubbon_cp1_bamboo.png',
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
        imageUrl: 'assets/images/cubbon_cp2_red_memorial.png',
        targetText: 'SESHADRI',
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
        imageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=800&auto=format&fit=crop',
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
        imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800&auto=format&fit=crop',
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
        imageUrl: 'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?q=80&w=800&auto=format&fit=crop',
        targetText: 'LOTUS',
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
        imageUrl: 'assets/images/panchvati_cp1_ramkund.png',
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
        imageUrl: 'assets/images/sula_cp1_vineyard.png',
      ),
    ],
  };
}
