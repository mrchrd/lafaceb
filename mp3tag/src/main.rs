use std::fs::File;
use std::path::Path;
use std::time::Duration;

use humanize_bytes::humanize_bytes_binary;
use humantime::format_duration;
use id3::{Tag, TagLike};
use symphonia::core::codecs;
use symphonia::core::formats::{FormatOptions};
use symphonia::core::io::MediaSourceStream;
use symphonia::core::meta::{MetadataOptions, StandardTagKey};
use symphonia::core::probe::Hint;
use symphonia::default::{get_probe};

fn main() {
  let mut args: Vec<String> = std::env::args().skip(1).collect();

  let mut replace_tags = false;
  if let Some(pos) = args.iter().position(|arg| arg == &"-y".to_string()) {
    replace_tags = true;
    args.remove(pos);
  }

  for filename in args {
    if Path::new(&filename).exists() {
      fileinfo(&filename, replace_tags);
    } else {
      println!();
      println!("Fichier non trouvé: {}", filename);
      println!();
    }
  }
}

fn fileinfo(filename: &String, replace_tags: bool) {
  // Set new artist and title
  // Assuming filename follows the pattern: "<artist> - <date> - <title>.<ext>"
  let mut new_artist = "Artist";
  let mut new_title = "Title";

  let file_prefix = Path::new(filename).file_stem().unwrap();
  let file_parts: Vec<&str> = file_prefix.to_str().unwrap().splitn(3, " - ").collect();

  if file_parts.len() == 3 {
    new_artist = file_parts[0].trim();
    new_title = file_parts[2].trim();
  }

  // Open file
  let file = File::open(filename).unwrap();

  // Get file size (in bytes)
  let size = file.metadata().unwrap().len();

  // Read file as a media stream
  let mss = MediaSourceStream::new(Box::new(file), Default::default());
  let hint = Hint::new();
  let fmt_opts: FormatOptions = Default::default();
  let meta_opts: MetadataOptions = Default::default();
  let mut probe = get_probe().format(&hint, mss, &fmt_opts, &meta_opts).unwrap();

  // Read codec parameters for the default track
  let params = &probe.format.default_track().unwrap().codec_params;

  // Get the codec type
  let codec: String;
  match params.codec {
    codecs::CODEC_TYPE_MP3 => codec = "MPEG-1 Layer 3 (MP3)".to_string(),
    _ => codec = "Inconnu".to_string()
  }

  // Get metadata
  let mut artist = String::new();
  let mut title = String::new();
  if let Some(mut metadata) = probe.metadata.get() {
    if let Some(latest) = metadata.skip_to_latest() {
      for tag in latest.tags().iter() {
        if let Some(std_key) = tag.std_key {
          match std_key {
            StandardTagKey::Artist => artist = tag.value.to_string(),
            StandardTagKey::TrackTitle => title = tag.value.to_string(),
            _ => {}
          }
        }
      }
    }
  }

  // Get the number of channels
  let mut channels: f32 = 0.0;
  match params.channels.unwrap().bits() {
    1 => channels = 1.0,
    3 => channels = 2.0,
    11 => channels = 2.1,
    63 => channels = 5.1,
    _ => {}
  }

  // Get the sample rate
  let samplerate = params.sample_rate.unwrap();

  // Get the duration
  let duration_time = params.time_base.unwrap().calc_time(params.n_frames.unwrap());
  let duration = Duration::from_secs_f64(duration_time.seconds as f64 + duration_time.frac);

  // Get the bitrate (in bytes per second)
  let bitrate = 8.0 * size as f64 / duration.as_secs_f64();

  // EDIT

  // Replace metadata
  if replace_tags {
    let mut tag = Tag::new();

    tag.set_title(new_title);
    tag.set_artist(new_artist);

    tag.write_to_path(filename, tag.version()).unwrap();
  }

  // VALIDATION

  // Duration

  let mut duration_ok = false;
  let duration_max = Duration::from_secs(59 * 60 + 40);
  let duration_min = Duration::from_secs(60 * 60);

  if duration > duration_min && duration < duration_max {
    duration_ok = true;
  }

  // DISPLAY

  println!();
  println!("Fichier: {}", filename);
  println!("Taille: {}", humanize_bytes_binary!(size));
  println!("Durée: {}{}", format_duration(Duration::from_secs(duration.as_secs())), if ! duration_ok {" (ERREUR)"} else {""});
  println!("Titre: {} -> {}", title, new_title);
  println!("Artiste: {} -> {}", artist, new_artist);
  println!("Codec: {}", codec);
  println!("Débit: {}/s", humanize_bytes_binary!(bitrate as u64));
  println!("Échantillonage: {} Hz", samplerate);
  println!("Canaux: {}", channels);
  println!();
}
