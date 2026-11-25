/// Generated from the copied Phase 2 packed PNGs.
/// Temporary QA data. Remove with assets/debug/phase2_png/.
class Phase23PageFile {
  const Phase23PageFile(this.page, this.bytes, this.sha256);

  final int page;
  final int bytes;
  final String sha256;
}

abstract final class Phase23Pages {
  static const int pageCount = 33;
  static const int width = 1241;
  static const int height = 1754;
  static const int totalBytes = 11911325;
  static const String fingerprint =
      'd60972fe641e5bd598ba1dde0d2e1e740d76819c22338450835bb4af2e9d11f2';
  static const String assetDirectory = 'assets/debug/phase2_png';

  static const List<Phase23PageFile> files = <Phase23PageFile>[
    Phase23PageFile(1, 344035,
        '277a21910f4e4547cafa1f294b9b27370e0897b9236b874a4005d8201b7b06b4'),
    Phase23PageFile(2, 334897,
        'c991deda711f4ca4829ec9ba224e0e9144e2a3e058918bb72cc53fd28d94e2a3'),
    Phase23PageFile(3, 357885,
        'f441d2182f928118597b9b3409e742faa414847e85e8a3782fcce30c1677c550'),
    Phase23PageFile(4, 347985,
        'c172934ffcce81991185696b2b4fdc53c77e2e4d550b61b5685d8a80c415acaf'),
    Phase23PageFile(5, 360441,
        '7652fdfb383d6cf37d4560d8601c45df88eb66af736d60ca8bc64e52f278f031'),
    Phase23PageFile(6, 384063,
        '248123d4cad97bb8741d128516023cca4801d258acaf4b11230e08803a23af30'),
    Phase23PageFile(7, 559660,
        '7cd9964f3962c598d4103b96dd06d269dc664f225a586410944c98824e5984c0'),
    Phase23PageFile(8, 290958,
        '1a11373318d3beb983caa9b522a001c625788b9c02e891fb2ce34b9ba64a9430'),
    Phase23PageFile(9, 301710,
        'b08b303ad5c22518bea66ef8058e35cc2398174abfba7c6eacf20d0072263cc0'),
    Phase23PageFile(10, 408144,
        '5259bf601aa769144701c4f6690618c11df240f197ef4294e962dd541a399191'),
    Phase23PageFile(11, 450599,
        'b57f8c284d19c9912c1ceacfcf419de5c5acbcb867bfdae8a2211ad79a3b75e9'),
    Phase23PageFile(12, 343694,
        '7167712c33ab7b02f1a9291d6425af8c6065dfc4edbf5b5c61e8ec6ba4cc43d7'),
    Phase23PageFile(13, 466255,
        '437e9bb46575b3c71e4ebb5a3c1d72f82238b4c38632486fcbc31a6465bc6544'),
    Phase23PageFile(14, 373308,
        '55ad281e5dfc87b5a2a078b62abb20c8f89cca7882bd836689c7c7c1300e5ddb'),
    Phase23PageFile(15, 375613,
        '69329fafcf2f1ec33d3c90127be32c7613aee8b741545d89d153f8c921e19cc0'),
    Phase23PageFile(16, 283401,
        '0d0e777bb58b728eb408d3875d24fa8f0bab107feee61d4604048f056b03461f'),
    Phase23PageFile(17, 411302,
        'dc2e07724e0abd5be194db0c3fecd0b93b1a5f270a943ec0c6ccb5441075791f'),
    Phase23PageFile(18, 298529,
        '79c681a17330daf146836ace89514fc6a8c3156ce75579b05e904cb9582804b0'),
    Phase23PageFile(19, 347678,
        'f046c9950c6dc02e699d5344decd04092dfee6c48065d0454d8f15313d05cf2d'),
    Phase23PageFile(20, 313837,
        'c3b7eac0569463f8513f7a10daae295a4c75860e1fea8b110b3b44fcc84b80cc'),
    Phase23PageFile(21, 341189,
        '5b6e3f68cdabaeda9b7004a53b718f1c0ac138fd43673038ccd29f21b69bf119'),
    Phase23PageFile(22, 338133,
        'b68f3179ffd0a77dcc49a35dd7d7ca5c21b4b31963cf2dfa94773e4308d726a3'),
    Phase23PageFile(23, 472504,
        '0bafcc1093e1baedecde7b6e3085e69b39b0842c8b2f89735dde3e86752b130c'),
    Phase23PageFile(24, 310270,
        'dddcd6110eced68a3c2b1c15cb77de0ee27ebd66027e3d533b5e42207a62cebe'),
    Phase23PageFile(25, 368619,
        '14d947c5b885b3e606df757be88499c8783d3908ae66e7adb45538a452361787'),
    Phase23PageFile(26, 352558,
        '079a499327d8a25525c8125a2ba8f508a43debea8ef67dfc91ef4ea2244a8fa2'),
    Phase23PageFile(27, 323522,
        '68525dc5f0c3926b8e0880b02d15389d5787e843f52680f3fdf2b30fcd154761'),
    Phase23PageFile(28, 396193,
        '6d67b9fe8e6717ff7f1451fdc8029dd71fc2ebaafa1137356612339ce11d1d2b'),
    Phase23PageFile(29, 359838,
        '64771c100b4bcf164c45636d32034b5ed79bd137313b6d8decd45ec5096b6fcb'),
    Phase23PageFile(30, 273275,
        'b83fb18402d9b8fe984b718bea0bfc1f21bb0a62b168baa5bde413044f85d9ab'),
    Phase23PageFile(31, 337120,
        '362fa5d9321cd2f4c3897fda29339a823ffa92d6cae72d5ac24db818e33117d8'),
    Phase23PageFile(32, 305339,
        '2c3b3fb68db7ac2379e7bea3ecd4d978afb88bdf6a146a293ecf630ee054e043'),
    Phase23PageFile(33, 378771,
        '0277c868169bd3af78b986a84c63e9d211d743a0fb61ea82b0d05b430b18af14'),
  ];

  static String assetFor(int page) {
    final String number = page.toString().padLeft(2, '0');
    return '$assetDirectory/page_$number.png';
  }

  static Phase23PageFile fileFor(int page) => files[page - 1];
}
