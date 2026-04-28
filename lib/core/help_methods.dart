class HelpMethods {
  String getProfileImage(String image) {
    String path = "";
    for (FotosPerfil f in FotosPerfil.values) {
      if (image == f.name) {
        path = f.path;
      }
    }

    return path;
  }
}

enum FotosPerfil {
  zorro('assets/images/fotos_perfil/zorro.png'),
  lemur('assets/images/fotos_perfil/lemur.png'),
  jabali('assets/images/fotos_perfil/jabali.png'),
  tucan('assets/images/fotos_perfil/tucan.png'),
  tejon('assets/images/fotos_perfil/tejon.png'),
  flamenco('assets/images/fotos_perfil/flamenco.png'),
  elefante('assets/images/fotos_perfil/elefante.png'),
  panda('assets/images/fotos_perfil/panda.png'),
  oso('assets/images/fotos_perfil/oso.png'),
  ciervo('assets/images/fotos_perfil/ciervo.png'),
  nutria('assets/images/fotos_perfil/nutria.png'),
  cheeta('assets/images/fotos_perfil/cheeta.png'),
  mapache('assets/images/fotos_perfil/mapache.png'),
  buho('assets/images/fotos_perfil/buho.png'),
  lobo('assets/images/fotos_perfil/lobo.png'),
  jirafa('assets/images/fotos_perfil/jirafa.png'),
  koala('assets/images/fotos_perfil/koala.png');

  final String path;
  const FotosPerfil(this.path);

  static String fromPath(String path) {
    String name = path.split('/').last;

    return FotosPerfil.values
        .firstWhere(
          (e) => e.name == name.substring(0, name.indexOf('.')),
          orElse: () => FotosPerfil.zorro, // Valor por defecto
        )
        .name;
  }
}
