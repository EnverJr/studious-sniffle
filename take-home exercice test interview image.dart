<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Badge Validator</title>
</head>
<body>
  <form id="badge-form">
    <label for="badge-input">Choose a badge file (PNG format only)</label>
    <input type="file" id="badge-input" accept=".png">
    <button type="submit">Validate Badge</button>
  </form>

  <div id="result"></div>

  <script>
    const jimp = require('jimp');

    // Function to validate the badge
    const validateBadge = async (inputImageBuffer) => {
      return new Promise(async (resolve, reject) => {
        try {
          const image = await jimp.read(inputImageBuffer);

          // Check the image size
          if (image.bitmap.width !== 512 || image.bitmap.height !== 512) {
            reject(new Error('Image size is not 512x512.'));
          }

          // Check the non-transparent pixels are within a circle
          const nonTransparentPixelCount = image.scan(0, 0, image.bitmap.width, image.bitmap.height, (x, y, index) => {
            const color = jimp.intToRGBA(image.bitmap.data[index]);
            if (color.a !== 0) {
              const centerX = image.bitmap.width / 2;
              const centerY = image.bitmap.height / 2;
              const radius = Math.sqrt(Math.pow(x - centerX, 2) + Math.pow(y - centerY, 2));
              if (radius > 256) {
                reject(new Error('Non-transparent pixels are not within a circle.'));
              }
            }
          });

          // Check the colors of the badge
          const happyColorCount = image.scan(0, 0, image.bitmap.width, image.bitmap.height, (x, y, index) => {
            const color = jimp.intToRGBA(image.bitmap.data[index]);
            if (index % 4 !== 3) { // Skip alpha channel
              const r = color.r;
              const g = color.g;
              const b = color.b;

              const happyColor =
                (r > 100 && g < 150 && b < 100) || // Blue
                (r < 128 && g > 128 && b < 128) || // Green
                (r > 180 && g < 100 && b < 100) || // Red
                (r > 180 && g > 180 && b < 100);  // Yellow

              return happyColor ? 1 : 0;
            }
            return 0;
          }).reduce((acc, val) => acc + val, 0);

          if (happyColorCount / (image.bitmap.width * image.bitmap.height) < 0.5) {
            reject(new Error('Badge colors do not give a "happy" feeling.'));
          }

          resolve();
        } catch (error) {
          console.error('Error validating badge:', error);
          reject(error);
        }
      });
    };

    // Form handling
    const form = document.getElementById('badge-form');
    const result = document.getElementById('result');

    form.addEventListener('submit', async (event) => {
      event.preventDefault();

      // Get the file input
      const fileInput = document.getElementById('badge-input');
      const file = fileInput.files[0];

      // Validate PNG format only
      if (!file.type.startsWith('image/png')) {
        result.innerHTML = 'Invalid file format. Please choose a PNG file.';
        return;
      }