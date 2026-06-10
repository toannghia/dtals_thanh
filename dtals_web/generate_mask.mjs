import fs from 'fs';
import path from 'path';
import * as turf from '@turf/turf';

// Define the input and output paths
const inputPath = path.join(process.cwd(), 'vnm_admin_boundaries.geojson', 'vnm_admin0.geojson');
const outputDir = path.join(process.cwd(), 'src', 'assets');
const outputPath = path.join(outputDir, 'vnm_inverted_mask.geojson');

async function generateMask() {
    try {
        console.log('Reading Vietnam GeoJSON...');
        const rawData = fs.readFileSync(inputPath, 'utf8');
        const geojsonData = JSON.parse(rawData);

        // Get the polygon/multipolygon feature for Vietnam
        const vietnamFeature = geojsonData.features.find((f) =>
            f.geometry.type === 'Polygon' || f.geometry.type === 'MultiPolygon'
        );

        if (!vietnamFeature) {
            throw new Error('Could not find Vietnam Polygon/MultiPolygon in GeoJSON');
        }

        console.log('Creating global bounding box...');
        // Create a global bounding box spanning the entire world
        const worldPolygon = turf.bboxPolygon([-180, -90, 180, 90]);

        console.log('Calculating inverted mask (subtracting Vietnam from World)...');

        // Turf difference subtracts the second polygon from the first
        // Due to the complexity of the MultiPolygon, we'll try difference.
        // However, turf.difference might have issues if geometry is invalid.
        let mask;
        try {
            mask = turf.difference(turf.featureCollection([worldPolygon, vietnamFeature]));
        } catch (e) {
            console.log("Difference failed with featureCollection, trying direct difference...");
            mask = turf.difference(worldPolygon, vietnamFeature);
        }

        if (!mask) {
            throw new Error('Failed to generate mask: turf.difference returned null. Data might be invalid.');
        }

        // Ensure output directory exists
        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }

        console.log('Writing output file...');
        fs.writeFileSync(outputPath, JSON.stringify(mask));

        console.log(`Successfully created mask at: ${outputPath}`);
    } catch (error) {
        console.error('Error generating mask:', error);
        process.exit(1);
    }
}

generateMask();
