import { useState } from 'react';
import { toast } from 'sonner';
import { auth } from '../firebase';
import type { MediaCategory } from '../media/mediaPolicy';

interface UseMediaUploadResult {
  isUploading: boolean;
  uploadFile: (file: File) => Promise<string | null>;
}

const MAX_IMAGE_DIMENSION = 1920;
const IMAGE_QUALITY = 0.82;

async function compressImage(file: File): Promise<File> {
  const compressibleTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (!compressibleTypes.includes(file.type)) return file;

  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = (event) => {
      const image = new Image();
      image.onload = () => {
        let { width, height } = image;
        if (width > MAX_IMAGE_DIMENSION || height > MAX_IMAGE_DIMENSION) {
          if (width > height) {
            height = Math.round((height * MAX_IMAGE_DIMENSION) / width);
            width = MAX_IMAGE_DIMENSION;
          } else {
            width = Math.round((width * MAX_IMAGE_DIMENSION) / height);
            height = MAX_IMAGE_DIMENSION;
          }
        }

        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const context = canvas.getContext('2d');
        if (!context) {
          resolve(file);
          return;
        }
        context.drawImage(image, 0, 0, width, height);
        canvas.toBlob((blob) => {
          if (!blob) {
            resolve(file);
            return;
          }
          const compressed = new File([blob], file.name, {
            type: 'image/jpeg',
            lastModified: Date.now(),
          });
          resolve(compressed.size < file.size ? compressed : file);
        }, 'image/jpeg', IMAGE_QUALITY);
      };
      image.onerror = () => resolve(file);
      image.src = String(event.target?.result || '');
    };
    reader.onerror = () => resolve(file);
    reader.readAsDataURL(file);
  });
}

function getErrorMessage(code: string | undefined): string {
  switch (code) {
    case 'UNAUTHORIZED':
    case 'INVALID_TOKEN':
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    case 'MEDIA_UPLOAD_PERMISSION_REQUIRED':
      return 'Tài khoản hiện tại không có quyền tải media.';
    case 'INVALID_CONTENT_TYPE':
      return 'Chỉ hỗ trợ ảnh JPEG, PNG hoặc WebP.';
    case 'INVALID_FILE_SIZE':
      return 'Ảnh sau nén phải có dung lượng không quá 5 MB.';
    case 'ORIGIN_NOT_ALLOWED':
      return 'Nguồn truy cập chưa được cho phép tải media.';
    case 'R2_NOT_CONFIGURED':
      return 'Kho media chưa được cấu hình. Vui lòng báo quản trị viên.';
    default:
      return 'Tải file thất bại, vui lòng thử lại.';
  }
}

export function useMediaUpload(category: MediaCategory = 'products'): UseMediaUploadResult {
  const [isUploading, setIsUploading] = useState(false);

  const uploadFile = async (file: File): Promise<string | null> => {
    if (!file.type.startsWith('image/')) {
      toast.error('Chỉ hỗ trợ tải ảnh JPEG, PNG hoặc WebP.');
      return null;
    }

    setIsUploading(true);
    try {
      const fileToUpload = await compressImage(file);
      const currentUser = auth.currentUser;
      if (!currentUser) {
        toast.error('Vui lòng đăng nhập bằng tài khoản quản trị trước khi tải ảnh.');
        return null;
      }

      const idToken = await currentUser.getIdToken();
      const presignResponse = await fetch('/api/media/upload-url', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${idToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          filename: fileToUpload.name,
          contentType: fileToUpload.type,
          size: fileToUpload.size,
          category,
        }),
      });

      const presignData = await presignResponse.json().catch(() => ({}));
      if (!presignResponse.ok || !presignData.uploadUrl || !presignData.publicUrl) {
        throw new Error(presignData.code || 'MEDIA_UPLOAD_URL_FAILED');
      }

      const uploadResponse = await fetch(presignData.uploadUrl, {
        method: 'PUT',
        headers: presignData.uploadHeaders || { 'Content-Type': fileToUpload.type },
        body: fileToUpload,
      });
      if (!uploadResponse.ok) {
        throw new Error('R2_UPLOAD_FAILED');
      }

      return presignData.publicUrl as string;
    } catch (error: any) {
      console.error('Media upload failed:', error?.message || error);
      toast.error(getErrorMessage(error?.message));
      return null;
    } finally {
      setIsUploading(false);
    }
  };

  return { isUploading, uploadFile };
}
