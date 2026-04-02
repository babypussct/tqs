import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Link from '@tiptap/extension-link';
import { Bold, Italic, Strikethrough, List, ListOrdered, Link as LinkIcon, Heading1, Heading2, RemoveFormatting } from 'lucide-react';
import { useEffect } from 'react';

interface RichTextEditorProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}

export function RichTextEditor({ value, onChange, placeholder }: RichTextEditorProps) {
  const editor = useEditor({
    extensions: [
      StarterKit,
      Link.configure({
        openOnClick: false,
        autolink: true,
      }),
    ],
    content: value,
    onUpdate: ({ editor }) => {
      onChange(editor.getHTML());
    },
    editorProps: {
      attributes: {
        class: 'prose prose-sm sm:prose lg:prose-lg xl:prose-2xl mx-auto focus:outline-none max-w-none p-4 min-h-[200px] text-gray-900 dark:text-gray-100',
      },
    },
  });

  // Keep content in sync with external value prop
  useEffect(() => {
    if (editor && value !== editor.getHTML()) {
      editor.commands.setContent(value, { emitUpdate: false });
    }
  }, [value, editor]);

  if (!editor) {
    return null;
  }

  return (
    <div className="border border-gray-300 dark:border-zinc-700 rounded-xl overflow-hidden bg-white dark:bg-zinc-950 flex flex-col w-full">
      {/* Toolbar */}
      <div className="flex flex-wrap items-center gap-1 p-2 border-b border-gray-200 dark:border-zinc-800 bg-gray-50 dark:bg-zinc-900/50">
        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <button
            type="button"
            onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
            className={`p-1.5 rounded-lg transition-colors ${editor.isActive('heading', { level: 2 }) ? 'bg-gray-200 dark:bg-zinc-700 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'}`}
            title="Đề mục 2"
          >
            <Heading1 className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
            className={`p-1.5 rounded-lg transition-colors ${editor.isActive('heading', { level: 3 }) ? 'bg-gray-200 dark:bg-zinc-700 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'}`}
            title="Đề mục 3"
          >
            <Heading2 className="w-4 h-4" />
          </button>
        </div>

        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <button
            type="button"
            onClick={() => editor.chain().focus().toggleBold().run()}
            disabled={!editor.can().chain().focus().toggleBold().run()}
            className={`p-1.5 rounded-lg transition-colors ${editor.isActive('bold') ? 'bg-gray-200 dark:bg-zinc-700 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'}`}
            title="In đậm"
          >
            <Bold className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => editor.chain().focus().toggleItalic().run()}
            disabled={!editor.can().chain().focus().toggleItalic().run()}
            className={`p-1.5 rounded-lg transition-colors ${editor.isActive('italic') ? 'bg-gray-200 dark:bg-zinc-700 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'}`}
            title="In nghiêng"
          >
            <Italic className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => editor.chain().focus().toggleStrike().run()}
            disabled={!editor.can().chain().focus().toggleStrike().run()}
            className={`p-1.5 rounded-lg transition-colors ${editor.isActive('strike') ? 'bg-gray-200 dark:bg-zinc-700 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'}`}
            title="Gạch ngang"
          >
            <Strikethrough className="w-4 h-4" />
          </button>
        </div>

        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <button
            type="button"
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            className={`p-1.5 rounded-lg transition-colors ${editor.isActive('bulletList') ? 'bg-gray-200 dark:bg-zinc-700 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'}`}
            title="Danh sách"
          >
            <List className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => editor.chain().focus().toggleOrderedList().run()}
            className={`p-1.5 rounded-lg transition-colors ${editor.isActive('orderedList') ? 'bg-gray-200 dark:bg-zinc-700 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'}`}
            title="Danh sách số"
          >
            <ListOrdered className="w-4 h-4" />
          </button>
        </div>

        <div className="flex items-center gap-1 border-r border-gray-300 dark:border-zinc-700 pr-2 mr-1">
          <button
            type="button"
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
            className={`p-1.5 rounded-lg transition-colors ${editor.isActive('link') ? 'bg-gray-200 dark:bg-zinc-700 text-gray-900 dark:text-white' : 'text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800'}`}
            title="Chèn liên kết"
          >
            <LinkIcon className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => editor.chain().focus().clearNodes().unsetAllMarks().run()}
            className="p-1.5 rounded-lg transition-colors text-gray-600 dark:text-zinc-400 hover:bg-gray-200 dark:hover:bg-zinc-800"
            title="Xóa định dạng"
          >
            <RemoveFormatting className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Editor Content Area */}
      <div className="flex-1 bg-white dark:bg-zinc-950 overflow-y-auto max-h-[500px] cursor-text" onClick={() => editor.commands.focus()}>
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
