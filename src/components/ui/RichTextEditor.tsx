import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Link from '@tiptap/extension-link';
import Underline from '@tiptap/extension-underline';
import Image from '@tiptap/extension-image';
import TextAlign from '@tiptap/extension-text-align';
import { TextStyle } from '@tiptap/extension-text-style';
import { Color } from '@tiptap/extension-color';
import Youtube from '@tiptap/extension-youtube';
import { Table } from '@tiptap/extension-table';
import TableRow from '@tiptap/extension-table-row';
import TableCell from '@tiptap/extension-table-cell';
import TableHeader from '@tiptap/extension-table-header';
import { 
  Bold, Italic, Strikethrough, Underline as UnderlineIcon, 
  List, ListOrdered, Link as LinkIcon, Heading1, Heading2, 
  RemoveFormatting, Image as ImageIcon, Video, Palette,
  AlignLeft, AlignCenter, AlignRight, AlignJustify, Table as TableIcon
} from 'lucide-react';
import { useEffect, useRef } from 'react';
import { useCloudinaryUpload } from '../../hooks/useCloudinaryUpload';

interface RichTextEditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export function RichTextEditor({ value, onChange, placeholder }: RichTextEditorProps) {
  const { isUploading, uploadFile } = useCloudinaryUpload();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        link: {
          openOnClick: false,
          autolink: true,
        }
      }),
      Underline,
      TextStyle,
      Color,
      Image.configure({
        inline: true,
        allowBase64: true,
      }),
      TextAlign.configure({
        types: ['heading', 'paragraph'],
      }),
      Youtube.configure({
        controls: false,
        nocookie: true,
      }),
      Table.configure({
        resizable: true,
      }),
      TableRow,
      TableHeader,
      TableCell,
    ],
    content: value,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
    editorProps: {
      attributes: {
        class: 'prose prose-sm sm:prose lg:prose-lg xl:prose-2xl mx-auto focus:outline-none max-w-none p-4 min-h-[300px] text-gray-900 dark:text-gray-100',
      },
    },
  });

  // Keep content in sync with external value prop
  useEffect(() => {
    if (editor && value !== editor.getHTML()) {
      editor.commands.setContent(value, { emitUpdate: false });
    }
  }, [value, editor]);

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const url = await uploadFile(file);
    if (url && editor) {
      editor.chain().focus().setImage({ src: url }).run();
    }
    // Reset file input
    e.target.value = '';
  };

  const addYoutubeVideo = () => {
    const url = prompt('Nhập đường dẫn YouTube (URL):');
    if (url && editor) {
      editor.commands.setYoutubeVideo({
        src: url,
        width: Math.max(320, parseInt(editor.view.dom.clientWidth.toString(), 10)) - 40,
        height: 480,
      });
    }
  };

  const insertTable = () => {
    if (editor) {
      editor.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run();
    }
  };

  if (!editor) {
    return null;
  }

  const ToolbarButton = ({ 
    onClick, 
    isActive = false, 
    disabled = false, 
    icon: Icon, 
    title 
  }: { 
    onClick: () => void, 
    isActive?: boolean, 
    disabled?: boolean, 
    icon: any, 
    title: string 
  }) => (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={`p-1.5 rounded-lg transition-colors ${
        isActive 
          ? 'bg-indigo-100 dark:bg-indigo-500/20 text-indigo-700 dark:text-indigo-400' 
          : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'
      } disabled:opacity-50`}
      title={title}
    >
      <Icon className="w-4 h-4" />
    </button>
  );

  return (
    <div className="border border-gray-300 dark:border-zinc-700 rounded-xl overflow-hidden bg-white dark:bg-zinc-950 flex flex-col w-full relative">
      {/* Uploading Overlay */}
      {isUploading && (
        <div className="absolute inset-0 bg-white/50 dark:bg-black/50 z-10 flex items-center justify-center backdrop-blur-sm">
          <div className="flex flex-col items-center gap-2">
            <div className="w-8 h-8 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
            <span className="text-sm font-medium text-indigo-700 dark:text-indigo-400">Đang tải ảnh lên...</span>
          </div>
        </div>
      )}

      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-1 p-2 border-b border-gray-200 dark:border-zinc-800 bg-gray-50 dark:bg-zinc-900/50 sticky top-0 z-0">
        
        {/* Headings */}
        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <ToolbarButton 
            onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()} 
            isActive={editor.isActive('heading', { level: 2 })} 
            icon={Heading1} title="Tiêu đề 2" 
          />
          <ToolbarButton 
            onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()} 
            isActive={editor.isActive('heading', { level: 3 })} 
            icon={Heading2} title="Tiêu đề 3" 
          />
        </div>

        {/* Text Formatting */}
        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <ToolbarButton 
            onClick={() => editor.chain().focus().toggleBold().run()} 
            isActive={editor.isActive('bold')} 
            icon={Bold} title="In đậm" 
          />
          <ToolbarButton 
            onClick={() => editor.chain().focus().toggleItalic().run()} 
            isActive={editor.isActive('italic')} 
            icon={Italic} title="In nghiêng" 
          />
          <ToolbarButton 
            onClick={() => editor.chain().focus().toggleUnderline().run()} 
            isActive={editor.isActive('underline')} 
            icon={UnderlineIcon} title="Gạch chân" 
          />
          <ToolbarButton 
            onClick={() => editor.chain().focus().toggleStrike().run()} 
            isActive={editor.isActive('strike')} 
            icon={Strikethrough} title="Gạch ngang" 
          />
          
          <div className="relative flex items-center ml-1 group">
            <label className="cursor-pointer p-1.5 rounded-lg text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800 transition-colors" title="Màu chữ">
              <Palette className="w-4 h-4" />
              <input
                type="color"
                onInput={event => editor.chain().focus().setColor((event.target as HTMLInputElement).value).run()}
                value={editor.getAttributes('textStyle').color || '#000000'}
                className="absolute opacity-0 w-0 h-0"
              />
            </label>
          </div>
        </div>

        {/* Text Alignment */}
        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <ToolbarButton 
            onClick={() => editor.chain().focus().setTextAlign('left').run()} 
            isActive={editor.isActive({ textAlign: 'left' })} 
            icon={AlignLeft} title="Căn trái" 
          />
          <ToolbarButton 
            onClick={() => editor.chain().focus().setTextAlign('center').run()} 
            isActive={editor.isActive({ textAlign: 'center' })} 
            icon={AlignCenter} title="Căn giữa" 
          />
          <ToolbarButton 
            onClick={() => editor.chain().focus().setTextAlign('right').run()} 
            isActive={editor.isActive({ textAlign: 'right' })} 
            icon={AlignRight} title="Căn phải" 
          />
          <ToolbarButton 
            onClick={() => editor.chain().focus().setTextAlign('justify').run()} 
            isActive={editor.isActive({ textAlign: 'justify' })} 
            icon={AlignJustify} title="Căn đều" 
          />
        </div>

        {/* Lists */}
        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <ToolbarButton 
            onClick={() => editor.chain().focus().toggleBulletList().run()} 
            isActive={editor.isActive('bulletList')} 
            icon={List} title="Danh sách" 
          />
          <ToolbarButton 
            onClick={() => editor.chain().focus().toggleOrderedList().run()} 
            isActive={editor.isActive('orderedList')} 
            icon={ListOrdered} title="Danh sách số" 
          />
        </div>

        {/* Media & Links & Tables */}
        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <ToolbarButton 
            onClick={() => {
              const previousUrl = editor.getAttributes('link').href;
              const url = window.prompt('URL', previousUrl);
              if (url === null) return;
              if (url === '') {
                editor.chain().focus().extendMarkRange('link').unsetLink().run();
                return;
              }
              editor.chain().focus().extendMarkRange('link').setLink({ href: url }).run();
            }} 
            isActive={editor.isActive('link')} 
            icon={LinkIcon} title="Chèn liên kết" 
          />
          
          <input 
            type="file" 
            ref={fileInputRef} 
            className="hidden" 
            accept="image/*" 
            onChange={handleImageUpload} 
          />
          <ToolbarButton 
            onClick={() => fileInputRef.current?.click()} 
            icon={ImageIcon} title="Chèn ảnh" 
          />
          
          <ToolbarButton 
            onClick={addYoutubeVideo} 
            isActive={editor.isActive('youtube')} 
            icon={Video} title="Chèn video YouTube" 
          />

          <ToolbarButton 
            onClick={insertTable} 
            isActive={editor.isActive('table')} 
            icon={TableIcon} title="Chèn Bảng" 
          />
        </div>

        <div className="flex items-center gap-1">
          <ToolbarButton 
            onClick={() => editor.chain().focus().clearNodes().unsetAllMarks().run()} 
            icon={RemoveFormatting} title="Xóa định dạng" 
          />
        </div>
      </div>

      {/* Editor Content Area */}
      <div className="flex-1 bg-white dark:bg-zinc-950 overflow-y-auto min-h-[400px] cursor-text" onClick={() => editor.commands.focus()}>
        {editor.isEmpty && (
          <div className="absolute p-4 text-gray-400 pointer-events-none select-none">
            {placeholder || 'Bắt đầu soạn thảo...'}
          </div>
        )}
        <EditorContent editor={editor} />
      </div>
    </div>
  );
}
