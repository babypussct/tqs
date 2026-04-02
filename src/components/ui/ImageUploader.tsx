import React, { useId } from 'react';
import { Upload, X } from 'lucide-react';
import { useCloudinaryUpload } from '../../hooks/useCloudinaryUpload';
import { toast } from 'sonner';

interface ImageUploaderProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  required?: boolean;
  className?: string;
  label?: string;
  onClear?: () => void;
}

export function ImageUploader({ 
  value, 
  onChange, 
  placeholder = 'https://...', 
  required = false,
  className = '',
  label,
  onClear
}: ImageUploaderProps) {
  const { isUploading, uploadFile } = useCloudinaryUpload();
  const inputId = useId();

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const url = await uploadFile(file);
    if (url) {
      onChange(url);
      toast.success('Thiết lập file thành công!');
    }
    
    // Reset file input so same file can be selected again
    e.target.value = '';
  };

  const isVideo = value.match(/\.(mp4|webm|ogg|mov)$/i);

  return (
    <div className={`w-full ${className}`}>
      {label && (
        <label className="block text-sm font-medium text-gray-700 dark:text-zinc-300 mb-2">
          {label} {required && '*'}
        </label>
      )}
      
      <div className="flex gap-4">
        {/* Input Wrapper */}
        <div className="flex-1 relative">
          <input 
            required={required} 
            type="url" 
            value={value} 
            onChange={e => onChange(e.target.value)} 
            className="w-full bg-gray-50 dark:bg-zinc-900 border border-gray-300 dark:border-zinc-700 rounded-xl px-4 py-3 pr-24 text-gray-900 dark:text-white focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all" 
            placeholder={placeholder} 
          />
          
          <div className="absolute right-2 top-1/2 -translate-y-1/2">
            <input 
              type="file" 
              id={inputId} 
              className="hidden" 
              accept="image/*,video/*" 
              onChange={handleFileChange} 
              disabled={isUploading}
            />
            <label 
              htmlFor={inputId} 
              className={`px-3 py-1.5 rounded-lg text-sm font-medium flex items-center gap-1 cursor-pointer transition-colors ${
                isUploading 
                  ? 'bg-gray-200 text-gray-400 dark:bg-zinc-800 dark:text-zinc-500 pointer-events-none' 
                  : 'bg-blue-50 text-blue-600 hover:bg-blue-100 dark:bg-blue-500/10 dark:text-blue-400 dark:hover:bg-blue-500/20'
              }`}
            >
              {isUploading ? (
                <div className="w-4 h-4 border-2 border-blue-600/50 dark:border-blue-400/50 border-t-transparent rounded-full animate-spin"></div>
              ) : (
                <Upload className="w-4 h-4" />
              )}
              Tải lên
            </label>
          </div>
        </div>

        {/* Action Buttons & Preview */}
        <div className="flex items-center gap-2 shrink-0">
          {value && (
            <div className="w-12 h-12 rounded-xl border border-gray-300 dark:border-zinc-700 overflow-hidden bg-gray-100 dark:bg-zinc-800 shrink-0">
              {isVideo ? (
                <video src={value} className="w-full h-full object-cover" muted playsInline />
              ) : (
                <img src={value} alt="Preview" className="w-full h-full object-cover" referrerPolicy="no-referrer" onError={(e) => (e.currentTarget.style.display = 'none')} />
              )}
            </div>
          )}
          
          {onClear && (
            <button 
              type="button"
              onClick={onClear}
              className="p-3 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-xl transition-colors shrink-0"
            >
              <X className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
