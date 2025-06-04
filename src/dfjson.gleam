import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}

pub type DFJson {
  Dict(val: dict.Dict(String, DFJson))
  List(val: List(DFJson))
  Comp(val: String)
  Str(val: String)
  Num(val: Float)
  Loc(x: Float, y: Float, z: Float, pitch: Float, yaw: Float)
  Vec(x: Float, y: Float, z: Float)
  Sound(
    sound: String,
    variant: option.Option(String),
    pitch: Float,
    volume: Float,
  )
  CustomSound(sound: String, pitch: Float, volume: Float)
  Particle(particle: String, cluster: ParticleCluster, data: ParticleData)
  Potion(potion: String, duration: Int, amplifier: Int)
}

pub type ParticleCluster {
  ParticleCluster(horizontal: Float, vertical: Float, amount: Int)
}

pub type ParticleData {
  ParticleData(
    x: Option(Float),
    y: Option(Float),
    z: Option(Float),
    motion_variation: Option(Float),
    size: Option(Float),
    size_variation: Option(Float),
    /// stored in hex
    color: Option(String),
    color_variation: Option(Float),
    color_fade: Option(String),
    roll: Option(Float),
    material: Option(String),
    opacity: Option(Float),
  )
}

fn int_as_float_decoder() -> decode.Decoder(Float) {
  use int <- decode.then(decode.int)
  decode.success(int.to_float(int))
}

fn number_decoder() -> decode.Decoder(Float) {
  decode.one_of(decode.float, or: [int_as_float_decoder()])
}

pub fn encode_df_json(df_json: DFJson) -> json.Json {
  case df_json {
    Dict(val:) ->
      json.object([
        #("id", json.string("dict")),
        #("val", json.dict(val, fn(string) { string }, encode_df_json)),
      ])
    List(val:) ->
      json.object([
        #("id", json.string("list")),
        #("val", json.array(val, encode_df_json)),
      ])
    Comp(val:) ->
      json.object([#("id", json.string("comp")), #("val", json.string(val))])
    Str(val:) ->
      json.object([#("id", json.string("str")), #("val", json.string(val))])
    Num(val:) ->
      json.object([#("id", json.string("num")), #("val", json.float(val))])
    Loc(x:, y:, z:, pitch:, yaw:) ->
      json.object([
        #("id", json.string("loc")),
        #("x", json.float(x)),
        #("y", json.float(y)),
        #("z", json.float(z)),
        #("pitch", json.float(pitch)),
        #("yaw", json.float(yaw)),
      ])
    Vec(x:, y:, z:) ->
      json.object([
        #("id", json.string("vec")),
        #("x", json.float(x)),
        #("y", json.float(y)),
        #("z", json.float(z)),
      ])
    Sound(sound:, variant:, pitch:, volume:) ->
      json.object([
        #("id", json.string("snd")),
        #("sound", json.string(sound)),
        #("variant", case variant {
          option.None -> json.null()
          option.Some(value) -> json.string(value)
        }),
        #("pitch", json.float(pitch)),
        #("volume", json.float(volume)),
      ])
    CustomSound(sound:, pitch:, volume:) ->
      json.object([
        #("id", json.string("csnd")),
        #("sound", json.string(sound)),
        #("pitch", json.float(pitch)),
        #("volume", json.float(volume)),
      ])
    Particle(particle:, cluster:, data:) ->
      json.object([
        #("id", json.string("particle")),
        #("particle", json.string(particle)),
        #("cluster", encode_particle_cluster(cluster)),
        #("data", encode_particle_data(data)),
      ])
    Potion(potion:, duration:, amplifier:) ->
      json.object([
        #("id", json.string("potion")),
        #("potion", json.string(potion)),
        #("duration", json.int(duration)),
        #("amplifier", json.int(amplifier)),
      ])
  }
}

pub fn encode_particle_cluster(particle_cluster: ParticleCluster) -> json.Json {
  let ParticleCluster(horizontal:, vertical:, amount:) = particle_cluster
  json.object([
    #("horizontal", json.float(horizontal)),
    #("vertical", json.float(vertical)),
    #("amount", json.int(amount)),
  ])
}

pub fn encode_particle_data(particle_data: ParticleData) -> json.Json {
  let ParticleData(
    x:,
    y:,
    z:,
    motion_variation:,
    size:,
    size_variation:,
    color:,
    color_variation:,
    color_fade:,
    roll:,
    material:,
    opacity:,
  ) = particle_data
  json.object([
    #("x", case x {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
    #("y", case y {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
    #("z", case z {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
    #("motion_variation", case motion_variation {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
    #("size", case size {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
    #("size_variation", case size_variation {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
    #("color", case color {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("color_variation", case color_variation {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
    #("color_fade", case color_fade {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("roll", case roll {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
    #("material", case material {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("opacity", case opacity {
      option.None -> json.null()
      option.Some(value) -> json.float(value)
    }),
  ])
}

pub fn df_json_decoder() -> decode.Decoder(DFJson) {
  use variant <- decode.field("id", decode.string)
  case variant {
    "dict" -> {
      use val <- decode.field(
        "val",
        decode.dict(decode.string, df_json_decoder()),
      )
      decode.success(Dict(val:))
    }
    "list" -> {
      use val <- decode.field("val", decode.list(df_json_decoder()))
      decode.success(List(val:))
    }
    "comp" -> {
      use val <- decode.field("val", decode.string)
      decode.success(Comp(val:))
    }
    "str" -> {
      use val <- decode.field("val", decode.string)
      decode.success(Str(val:))
    }
    "num" -> {
      use val <- decode.field("val", number_decoder())
      decode.success(Num(val:))
    }
    "loc" -> {
      use x <- decode.field("x", number_decoder())
      use y <- decode.field("y", number_decoder())
      use z <- decode.field("z", number_decoder())
      use pitch <- decode.field("pitch", number_decoder())
      use yaw <- decode.field("yaw", number_decoder())
      decode.success(Loc(x:, y:, z:, pitch:, yaw:))
    }
    "vec" -> {
      use x <- decode.field("x", number_decoder())
      use y <- decode.field("y", number_decoder())
      use z <- decode.field("z", number_decoder())
      decode.success(Vec(x:, y:, z:))
    }
    "snd" -> {
      use sound <- decode.field("sound", decode.string)
      use variant <- decode.field("variant", decode.optional(decode.string))
      use pitch <- decode.field("pitch", number_decoder())
      use volume <- decode.field("volume", number_decoder())
      decode.success(Sound(sound:, variant:, pitch:, volume:))
    }
    "csnd" -> {
      use sound <- decode.field("sound", decode.string)
      use pitch <- decode.field("pitch", number_decoder())
      use volume <- decode.field("volume", number_decoder())
      decode.success(CustomSound(sound:, pitch:, volume:))
    }
    "particle" -> {
      use particle <- decode.field("particle", decode.string)
      use cluster <- decode.field("cluster", particle_cluster_decoder())
      use data <- decode.field("data", particle_data_decoder())
      decode.success(Particle(particle:, cluster:, data:))
    }
    "potion" -> {
      use potion <- decode.field("potion", decode.string)
      use duration <- decode.field("duration", decode.int)
      use amplifier <- decode.field("amplifier", decode.int)
      decode.success(Potion(potion:, duration:, amplifier:))
    }
    _ -> decode.failure(Num(0.0), "DFJson")
  }
}

pub fn particle_cluster_decoder() -> decode.Decoder(ParticleCluster) {
  use horizontal <- decode.field("horizontal", number_decoder())
  use vertical <- decode.field("vertical", number_decoder())
  use amount <- decode.field("amount", decode.int)
  decode.success(ParticleCluster(horizontal:, vertical:, amount:))
}

pub fn particle_data_decoder() -> decode.Decoder(ParticleData) {
  use x <- decode.field("x", decode.optional(number_decoder()))
  use y <- decode.field("y", decode.optional(number_decoder()))
  use z <- decode.field("z", decode.optional(number_decoder()))
  use motion_variation <- decode.field(
    "motion_variation",
    decode.optional(number_decoder()),
  )
  use size <- decode.field("size", decode.optional(number_decoder()))
  use size_variation <- decode.field(
    "size_variation",
    decode.optional(number_decoder()),
  )
  use color <- decode.field("color", decode.optional(decode.string))
  use color_variation <- decode.field(
    "color_variation",
    decode.optional(number_decoder()),
  )
  use color_fade <- decode.field("color_fade", decode.optional(decode.string))
  use roll <- decode.field("roll", decode.optional(number_decoder()))
  use material <- decode.field("material", decode.optional(decode.string))
  use opacity <- decode.field("opacity", decode.optional(number_decoder()))
  decode.success(ParticleData(
    x:,
    y:,
    z:,
    motion_variation:,
    size:,
    size_variation:,
    color:,
    color_variation:,
    color_fade:,
    roll:,
    material:,
    opacity:,
  ))
}
