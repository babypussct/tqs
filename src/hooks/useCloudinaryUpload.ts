import { useState } from 'react';
import { toast } from 'sonner';

interface UseCloudinaryUploadResult {
  isUploading: boolean;
  uploadFile: (file: File) => Promise<string | null>;
}

export function useCloudinaryUpload(): UseCloudinaryUploadResult {
  const [isUploading, setIsUploading] = useState(false);

  const uploadFile = async (file: File): Promise<string | null> => {
    const cloudName = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME;
    const uploadPreset = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET;

    if (!cloudName || !uploadPreset) {
      toast.error('Cấu hình Cloudinary chưa được khởi tạo! (Thiếu biến môi trường)');
      return null;
    }

    setIsUploading(true);

    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('upload_preset', uploadPreset);

      // Using auto resource_type correctly handles both videos and images
      const res = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/auto/upload`, {
        method: 'POST',
        body: formData,
      });

      if (!res.ok) {
        throw new Error('Lỗi upload file API');
      }

      const data = await res.json();
      return data.secure_url;
    } catch (error) {
      console.error('Lỗi khi tải file lên Cloudinary:', error);
      toast.error('Tải file thất bại, vui lòng thử lại.');
      return null;
    } finally {
      setIsUploading(false);
    }
  };

  return { isUploading, uploadFile };
}
