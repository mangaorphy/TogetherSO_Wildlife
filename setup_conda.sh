#!/bin/bash
# Conda Environment Setup for TogetherSO Wildlife Project

echo "🐍 Setting up Conda environment for TogetherSO Wildlife..."
echo ""

# Check if conda is installed
if ! command -v conda &> /dev/null; then
    echo "❌ Error: Conda is not installed."
    echo "Please install Miniconda or Anaconda first:"
    echo "https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi

echo "✓ Conda found: $(conda --version)"
echo ""

# Remove existing environment if it exists
echo "Checking for existing environment..."
if conda env list | grep -q "togetherso_wildlife"; then
    echo "Removing existing togetherso_wildlife environment..."
    conda env remove -n togetherso_wildlife -y
fi

# Create conda environment from yml file
echo ""
echo "Creating conda environment from environment.yml..."
conda env create -f environment.yml

# Check if creation was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Conda environment created successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Activate the environment:"
    echo "   conda activate togetherso_wildlife"
    echo ""
    echo "2. Start the API server:"
    echo "   cd api"
    echo "   python main.py"
    echo ""
    echo "3. Or run the Flutter app:"
    echo "   cd togetherso_app"
    echo "   flutter run"
    echo ""
else
    echo ""
    echo "❌ Error creating conda environment"
    echo "Please check the error messages above"
    exit 1
fi
