import base64

# Prompt the user for the Base64 string
data = input("Enter the Base64 string: ")

try:
    # Decode and write to file
    with open("decoded_file.txt", "wb") as f:
        f.write(base64.b64decode(data.strip()))

    print("✅ File saved as decoded_file.txt")
except Exception as e:
    print(f"❌ Error: {e}")
