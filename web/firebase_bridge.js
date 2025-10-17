// Custom Firebase Storage Bridge
window.firebaseBridge = {
  async uploadFile(path, file, metadata) {
    try {
      const storage = window.firebase.storage();
      const storageRef = storage.ref();
      const fileRef = storageRef.child(path);
      
      // Add upload progress tracking
      const uploadTask = fileRef.put(file, metadata);
      
      // Return a promise that resolves with the final result
      return new Promise((resolve, reject) => {
        uploadTask.on('state_changed',
          // Progress callback
          (snapshot) => {
            const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            window.dispatchEvent(new CustomEvent('uploadProgress', { 
              detail: { path, progress } 
            }));
          },
          // Error callback
          (error) => {
            resolve({
              success: false,
              error: error.message
            });
          },
          // Success callback
          async () => {
            try {
              const downloadUrl = await uploadTask.snapshot.ref.getDownloadURL();
              resolve({
                success: true,
                url: downloadUrl,
                metadata: uploadTask.snapshot.metadata
              });
            } catch (error) {
              resolve({
                success: false,
                error: error.message
              });
            }
          }
        );
      });
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  },
  
  async deleteFile(path) {
    try {
      const storage = window.firebase.storage();
      const storageRef = storage.ref();
      const fileRef = storageRef.child(path);
      
      await fileRef.delete();
      return {
        success: true
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
};
