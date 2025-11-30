#!/bin/bash

# EcoSight API - Installation Script with YAMNet Fix
# This script installs all dependencies including tensorflow-hub

echo "=========================================="
echo "🚀 EcoSight API - Installing Dependencies"
echo "=========================================="
echo ""

# Check if in virtual environment
if [[ "$VIRTUAL_ENV" != "" ]]; then
    echo "✅ Virtual environment detected: $VIRTUAL_ENV"
else
    echo "⚠️  Warning: No virtual environment detected"
    echo "   It's recommended to use a virtual environment"
    echo "   Run: python3 -m venv venv && source venv/bin/activate"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "📦 Installing Python dependencies..."
echo "   This may take 5-10 minutes..."
echo ""

# Upgrade pip first
pip3 install --upgrade pip

# Install dependencies
pip3 install -r requirements.txt

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Installation Complete!"
    echo "=========================================="
    echo ""
    echo "Installed packages:"
    echo "  ✓ FastAPI & Uvicorn (API framework)"
    echo "  ✓ TensorFlow & TensorFlow Hub (ML)"
    echo "  ✓ Librosa & SoundFile (audio processing)"
    echo "  ✓ NumPy & Pydantic (utilities)"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Start the server: python3 main.py"
    echo "  2. Test the API: python3 test_api.py"
    echo "  3. Open docs: http://localhost:8000/docs"
    echo ""
    echo "📝 Read FIX_EXPLANATION.md for details about YAMNet fix"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "❌ Installation Failed!"
    echo "=========================================="
    echo ""
    echo "Common issues:"
    echo "  • Python version incompatible (need 3.9+)"
    echo "  • Missing system dependencies"
    echo "  • Network issues downloading packages"
    echo ""
    echo "Try:"
    echo "  pip3 install --upgrade pip"
    echo "  pip3 install -r requirements-minimal.txt"
    echo "=========================================="
    exit 1
fi
