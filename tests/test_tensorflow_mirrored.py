import tensorflow as tf

print("=== Test: TensorFlow MirroredStrategy ===")

try:
    gpus = tf.config.list_physical_devices("GPU")
    print(f"Available GPUs: {len(gpus)}")
    
    for gpu in gpus:
        try:
            tf.config.experimental.set_memory_growth(gpu, True)
        except RuntimeError:
            pass
    
    if len(gpus) < 2:
        print("[SKIP] Need 2+ GPUs for MirroredStrategy test")
    else:
        strategy = tf.distribute.MirroredStrategy()
        print(f"Number of devices in strategy: {strategy.num_replicas_in_sync}")
        
        with strategy.scope():
            model = tf.keras.Sequential([
                tf.keras.layers.Dense(32, activation="relu", input_shape=(10,)),
                tf.keras.layers.Dense(1)
            ])
            model.compile(optimizer="adam", loss="mse")
        
        # Use batch size that's evenly divisible by number of GPUs
        batch_size = 64  # 32 per GPU with 2 GPUs
        x = tf.random.normal((128, 10))
        y = tf.random.normal((128, 1))
        
        history = model.fit(x, y, batch_size=batch_size, epochs=1, verbose=0)
        
        loss = history.history["loss"][0]
        print(f"[PASS] TensorFlow MirroredStrategy successful, loss: {loss:.4f}")
        
except Exception as e:
    print(f"[FAIL] TensorFlow MirroredStrategy test failed: {e}")
    import traceback
    traceback.print_exc()
