import xml.etree.ElementTree as ET
import json

# Parse the KML file
kml_file = ".\public\FixedVertiportsSettings_V1_LI.kml"  # Replace with your actual file path
tree = ET.parse(kml_file)
root = tree.getroot()

# Define the namespace
ns = {"kml": "http://www.opengis.net/kml/2.2"}

# Extracting the first coordinate from each Placemark
airports = []
index = 0

for placemark in root.findall(".//kml:Placemark", ns):
    name = placemark.find("kml:name", ns).text
    coordinates_element = placemark.find(".//kml:coordinates", ns)

    if coordinates_element is not None:
        coordinates_text = coordinates_element.text.strip()
        first_coord = coordinates_text.split()[0]  # Get only the first coordinate
        lon, lat, alt = map(float, first_coord.split(","))

        # Append the extracted data to JSON format
        airports.append({
            "index": index,
            "longitude": lon,
            "latitude": lat,
            "height": alt,
            "cartesian": {
                "x": None,  # Leave empty
                "y": None,
                "z": None
            },
            "neuDistances": {
                "north": None,
                "east": None,
                "up": None
            }
        })
        index += 1

# Save to JSON file
output_json_file = ".\public\FixedVertiportsSettings_V1_LI.json"
with open(output_json_file, "w") as f:
    json.dump(airports, f, indent=4)

print(f"Extracted {len(airports)} coordinates and saved to {output_json_file}")
