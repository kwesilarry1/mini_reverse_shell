import base64

# Prompt the user to enter the file path
file_path = input("Enter the path of the file to encode: ")

try:
    with open(file_path, "rb") as f:
        encoded = base64.b64encode(f.read()).decode()
    
    output_file = file_path + ".b64"  # Save output as a new file
    with open(output_file, "w") as out_f:
        out_f.write(encoded)
    
    print(f"Base64 encoded data saved to: {output_file}")

except FileNotFoundError:
    print("Error: The specified file was not found.")
except Exception as e:
    print(f"An error occurred: {e}")
