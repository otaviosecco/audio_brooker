import youtubedl from 'youtube-dl-exec';
import fs from 'fs';
import axios from 'axios';
import path from 'path';

export async function downloadAndConvertToMp3(youtubeUrl) {
  try {
    console.log('Starting download and conversion...');

    // Fetch video info
    const info = await youtubedl(youtubeUrl, {
      dumpSingleJson: true,
      noWarnings: true,
    });
    console.log('Video information fetched:', info.title);

    // Download thumbnail
    const thumbnailUrl = info.thumbnail;
    const thumbnailPath = 'thumbnail.jpg';
    const response = await axios({
      url: thumbnailUrl,
      responseType: 'stream',
    });

    const writer = fs.createWriteStream(thumbnailPath);
    response.data.pipe(writer);
    console.log('Downloading thumbnail...');

    await new Promise((resolve, reject) => {
      writer.on('finish', resolve);
      writer.on('error', reject);
    });
    console.log('Thumbnail downloaded.');

    const sanitizedTitle = info.title.replace(/[<>:"/\\|?*]+/g, '');
    const outputPath = path.join('public', 'audios', `${sanitizedTitle}.mp3`);
    console.log('MP3 output path:', outputPath);

    // Download and convert to MP3
    await youtubedl(youtubeUrl, {
      audioFormat: 'mp3',
      output: outputPath,
      extractAudio: true,
      audioQuality: 128,
      addMetadata: true,
      embedThumbnail: true,
    });
    console.log('Download and conversion finished.');

    // Clean up thumbnail
    fs.unlinkSync(thumbnailPath);

    return { status: 200, timestamps: info.chapters || [] };
  } catch (error) {
    console.error('Error fetching video info or converting:', error);
    throw error;
  }
}