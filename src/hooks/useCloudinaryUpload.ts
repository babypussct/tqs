import { useState } from 'react';
import { toast } from 'sonner';

interface UseCloudinaryUploadResult {
  isUploading: boolean;
  uploadFile: (file: File) => Promise<string | null>;
}

/** Kích thước tối đa và quality khi nén ảnh client-side trước upload */
const MAX_IMAGE_DIMENSION = 1920;
const IMAGE_QUALITY = 0.82; // 0.82 = cân bằng chất lượng/size tốt nhất

/**
 * Nén ảnh phía client trước khi upload lên Cloudinary.
 * - Resize về max 1920px (giữ tỷ lệ)
 * - Nén JPEG quality 0.82
 * - Giảm ~60% dung lượng so với ảnh gốc
 * - Video/GIF/SVG: trả về file gốc, không xử lý
 */
async function compressImage(file: File): Promise<File> {
  // Chỉ nén ảnh JPEG/PNG/WebP — bỏ qua video, GIF, SVG
  const compressibleTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (!compressibleTypes.includes(file.type)) return file;

  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        // Tính toán kích thước mới (giữ tỷ lệ)
        let { width, height } = img;
        if (width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION) {
          if (width > height) {
            height = Math.round((height * MAX_IMAGE_DIMENSION) / width);
            width = MAX_IMAGE_DIMENSION;
          } else {
            width = Math.round((width * MAX_IMAGE_DIMENSION) / height);
            height = MAX_IMAGE_DIMENSION;
          }
        }

        // Vẽ lên canvas và xuất ra JPEG nén
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        if (!ctx) { resolve(file); return; }
        ctx.drawImage(img, 0, 0, width, height);

        canvas.toBlob(
          (blob) => {
            if (!blob) { resolve(file); return; }
            const compressed = new File([blob], file.name, {
              type: 'image/jpeg',
              lastModified: Date.now(),
            });
            // Chỉ dùng bản nén nếu nhỏ hơn file gốc
            resolve(compressed.size < file.size ? compressed : file);
          },
          'image/jpeg',
          IMAGE_QUALITY
        );
      };
      img.onerror = () => resolve(file);
      img.src = e.target?.result as string;
    };
    reader.onerror = () => resolve(file);
    reader.readAsDataURL(file);
  });
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
      // Nén ảnh client-side trước khi upload (video/GIF/SVG không bị ảnh hưởng)
      const fileToUpload = await compressImage(file);

      const formData = new FormData();
      formData.append('file', fileToUpload);
      formData.append('upload_preset', uploadPreset);

      // resource_type=auto xử lý đúng cả video lẫn ảnh
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
