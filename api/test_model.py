"""
Test the TFLite model to diagnose prediction issues
"""
import numpy as np
import tensorflow as tf

print("="*70)
print("TESTING TFLITE MODEL")
print("="*70)

# Load TFLite model
model_path = '/Users/cococe/Desktop/TogetherSO_Wildlife/api/togetherso_yamnet_model.tflite'
interpreter = tf.lite.Interpreter(model_path=model_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"\n✓ Model loaded: {model_path}")
print(f"  Input shape:  {input_details[0]['shape']}")
print(f"  Output shape: {output_details[0]['shape']}")
print(f"  Input dtype:  {input_details[0]['dtype']}")
print(f"  Output dtype: {output_details[0]['dtype']}")

# Test with different inputs
print("\n" + "="*70)
print("TESTING WITH DIFFERENT INPUTS")
print("="*70)

test_cases = [
    ("Zeros", np.zeros((1, 1024), dtype=np.float32)),
    ("Ones", np.ones((1, 1024), dtype=np.float32)),
    ("Random Small", np.random.randn(1, 1024).astype(np.float32) * 0.1),
    ("Random Large", np.random.randn(1, 1024).astype(np.float32) * 10),
]

for name, test_input in test_cases:
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])
    
    # Apply softmax
    exp_output = np.exp(output[0] - np.max(output[0]))
    probs = exp_output / np.sum(exp_output)
    
    print(f"\n{name}:")
    print(f"  Input range: [{test_input.min():.3f}, {test_input.max():.3f}]")
    print(f"  Raw output: {output[0]}")
    print(f"  Probabilities: {probs}")
    print(f"  Max prob: {probs.max():.4f} (class {probs.argmax()})")

# Check if model has proper weights
print("\n" + "="*70)
print("DIAGNOSIS")
print("="*70)

# If all inputs give similar outputs, model might not be trained
all_similar = True
first_output = None

for name, test_input in test_cases:
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])
    
    if first_output is None:
        first_output = output
    elif not np.allclose(output, first_output, atol=0.1):
        all_similar = False
        break

if all_similar:
    print("❌ PROBLEM DETECTED:")
    print("   All different inputs produce nearly identical outputs!")
    print("   This suggests:")
    print("   1. Model weights are not properly trained")
    print("   2. Model conversion lost information")
    print("   3. Model architecture has issues")
    print("\n💡 SOLUTION:")
    print("   You need to reconvert the model from the Keras file:")
    print("   Run: python3 reconvert_model.py")
else:
    print("✅ Model responds differently to different inputs")
    print("   Model architecture seems OK")
    print("\n⚠️  However, if predictions are still poor:")
    print("   1. Check training data quality")
    print("   2. Model might need more training")
    print("   3. YAMNet embeddings might not match training")

print("="*70)
