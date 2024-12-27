// Use ffmpeg to read metadata and save as JSON files in the data folder.

const fs = require('fs');
const path = require('path');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegStatic = require('ffmpeg-static');

// Set the path to the ffmpeg binary
ffmpeg.setFfmpegPath(ffmpegStatic);

// Define directories
const audioDir = path.join(__dirname, 'public/audios');
const dataDir = path.join(__dirname, 'data');

// Ensure data directory exists
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir);
}

// Read audio files from the audio directory
fs.readdir(audioDir, (err, files) => {
  if (err) {
    console.error('Error reading directory:', err);
    return;
  }

  files.forEach(file => {
    const filePath = path.join(audioDir, file);

    // Use ffprobe to get metadata
    ffmpeg.ffprobe(filePath, (err, metadata) => {
      if (err) {
        console.error(`Error reading metadata for ${file}:`, err);
        return;
      }

      const audioInfo = {
        title: metadata.format.tags?.title || path.parse(file).name,
        artist: metadata.format.tags?.artist || 'Unknown Artist',
        album: metadata.format.tags?.album || 'Unknown Album',
        duration: metadata.format.duration
      };

      const jsonFileName = `${path.parse(file).name}.json`;
      const jsonFilePath = path.join(dataDir, jsonFileName);

      // Write metadata to JSON file
      fs.writeFile(jsonFilePath, JSON.stringify(audioInfo, null, 2), (err) => {
        if (err) {
          console.error(`Error writing JSON for ${file}:`, err);
        } else {
          console.log(`Metadata for ${file} saved to ${jsonFileName}`);
        }
      });
    });
  });
});