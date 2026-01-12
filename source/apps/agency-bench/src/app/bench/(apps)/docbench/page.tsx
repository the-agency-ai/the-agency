'use client';

import { useState, useEffect, useCallback, useRef, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { readFile, writeFile, getProjectRoot, getPendingOpen } from '@/lib/tauri';

interface TreeNode {
  name: string;
  path: string;
  isDirectory: boolean;
  children?: TreeNode[];
}

function DocBenchContent() {
  const searchParams = useSearchParams();
  const initialFile = searchParams.get('file');

  const [tree, setTree] = useState<TreeNode | null>(null);
  const [expandedDirs, setExpandedDirs] = useState<Set<string>>(new Set());
  const [selectedFile, setSelectedFile] = useState<string | null>(initialFile);
  const [content, setContent] = useState<string>('');
  const [editContent, setEditContent] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [projectRoot, setProjectRoot] = useState<string>('');
  const [browseRoot, setBrowseRoot] = useState<string>('claude');
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);
  const [favorites, setFavorites] = useState<string[]>([]);
  const [selectionPopup, setSelectionPopup] = useState<{ x: number; y: number; text: string; start: number; end: number } | null>(null);
  const [principalName, setPrincipalName] = useState<string>('');
  const [commentInput, setCommentInput] = useState<string>('');
  const [showCommentForm, setShowCommentForm] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const clickTimerRef = useRef<NodeJS.Timeout | null>(null);
  // Store selection data in ref to avoid React state timing issues
  const selectionDataRef = useRef<{ text: string; start: number; end: number } | null>(null);

  // Resizable pane state
  const [sidebarWidth, setSidebarWidth] = useState(288); // w-72 = 18rem = 288px
  const isResizing = useRef(false);
  const containerRef = useRef<HTMLDivElement>(null);

  // Create document state
  const [showCreateMenu, setShowCreateMenu] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState<'request' | 'observe' | 'note' | null>(null);

  // Insert menu state
  const [showInsertMenu, setShowInsertMenu] = useState(false);
  const [hasTextSelection, setHasTextSelection] = useState(false);
  const [showAltTextModal, setShowAltTextModal] = useState(false);
  const [pendingImagePath, setPendingImagePath] = useState<string | null>(null);
  const [imageAltText, setImageAltText] = useState('');

  // Web link modal state
  const [showWebLinkModal, setShowWebLinkModal] = useState(false);
  const [webLinkUrl, setWebLinkUrl] = useState('');
  const [webLinkText, setWebLinkText] = useState('');

  // Object reference modal state
  const [showObjectRefModal, setShowObjectRefModal] = useState<'bug' | 'request' | null>(null);
  const [objectRefId, setObjectRefId] = useState('');

  // Settings modal state
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [settingsPrincipalName, setSettingsPrincipalName] = useState('');
  const [createAgentName, setCreateAgentName] = useState('');
  const [createSummary, setCreateSummary] = useState('');
  const [createPriority, setCreatePriority] = useState<'Low' | 'Normal' | 'High' | 'Critical'>('Normal');
  const [createObservation, setCreateObservation] = useState('');
  const [createFilename, setCreateFilename] = useState('');
  const [isCreating, setIsCreating] = useState(false);

  // Template modal state
  const [showTemplateModal, setShowTemplateModal] = useState(false);
  const [templates] = useState([
    { id: 'bug-report', name: 'Bug Report', description: 'Report a bug or issue' },
    { id: 'meeting-notes', name: 'Meeting Notes', description: 'Notes from a meeting' },
    { id: 'decision-record', name: 'Decision Record', description: 'Document a decision' },
  ]);

  // Client-side Tauri detection (avoids hydration mismatch)
  const [isTauriClient, setIsTauriClient] = useState<boolean | null>(null); // null = not yet determined
  useEffect(() => {
    setIsTauriClient(typeof window !== 'undefined' && !!(window as any).__TAURI__);
  }, []);

  // Load settings from localStorage
  useEffect(() => {
    const stored = localStorage.getItem('agencybench-favorites');
    if (stored) {
      try {
        setFavorites(JSON.parse(stored));
      } catch {
        // Ignore parse errors
      }
    }
    // Load browse root
    const storedRoot = localStorage.getItem('agencybench-browse-root');
    if (storedRoot) {
      setBrowseRoot(storedRoot);
    }
    // Load principal name - if not set, show settings modal on first run
    const storedPrincipal = localStorage.getItem('agencybench-principal');
    if (storedPrincipal) {
      setPrincipalName(storedPrincipal);
      setSettingsPrincipalName(storedPrincipal);
    } else {
      // First run - prompt for principal name
      setShowSettingsModal(true);
    }
  }, []);

  // Save principal name to localStorage
  useEffect(() => {
    if (principalName) {
      localStorage.setItem('agencybench-principal', principalName);
    }
  }, [principalName]);

  // Save favorites to localStorage
  useEffect(() => {
    localStorage.setItem('agencybench-favorites', JSON.stringify(favorites));
  }, [favorites]);

  // Save browse root to localStorage
  useEffect(() => {
    localStorage.setItem('agencybench-browse-root', browseRoot);
  }, [browseRoot]);

  // Check for pending file to open from CLI
  useEffect(() => {
    async function checkPendingOpen() {
      try {
        const pending = await getPendingOpen();
        if (pending?.file) {
          console.log('[DocBench] Opening pending file:', pending.file);
          setSelectedFile(pending.file);
        }
      } catch (err) {
        console.error('[DocBench] Error checking pending open:', err);
      }
    }
    checkPendingOpen();
  }, []);

  // Load and save sidebar width
  useEffect(() => {
    const storedWidth = localStorage.getItem('docbench-sidebar-width');
    if (storedWidth) {
      setSidebarWidth(parseInt(storedWidth, 10));
    }
  }, []);

  useEffect(() => {
    localStorage.setItem('docbench-sidebar-width', sidebarWidth.toString());
  }, [sidebarWidth]);

  // Handle resize drag
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    isResizing.current = true;
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
  }, []);

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      if (!isResizing.current || !containerRef.current) return;
      const containerRect = containerRef.current.getBoundingClientRect();
      const newWidth = e.clientX - containerRect.left;
      // Clamp between 200px and 500px
      setSidebarWidth(Math.min(500, Math.max(200, newWidth)));
    };

    const handleMouseUp = () => {
      if (isResizing.current) {
        isResizing.current = false;
        document.body.style.cursor = '';
        document.body.style.userSelect = '';
      }
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    return () => {
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, []);

  // Build tree from file list
  const buildTree = useCallback((files: string[], root: string, browseDir: string): TreeNode => {
    const fullBrowsePath = `${root}/${browseDir}`;
    const rootNode: TreeNode = {
      name: browseDir,
      path: fullBrowsePath,
      isDirectory: true,
      children: [],
    };

    // Filter to files under browse root
    const relevantFiles = files.filter((f) => f.startsWith(fullBrowsePath + '/'));

    for (const file of relevantFiles) {
      const relativePath = file.replace(fullBrowsePath + '/', '');
      const parts = relativePath.split('/');

      let current = rootNode;
      let currentPath = fullBrowsePath;

      for (let i = 0; i < parts.length; i++) {
        const part = parts[i];
        currentPath = `${currentPath}/${part}`;
        const isLast = i === parts.length - 1;

        if (!current.children) current.children = [];

        let child = current.children.find((c) => c.name === part);
        if (!child) {
          child = {
            name: part,
            path: currentPath,
            isDirectory: !isLast,
            children: isLast ? undefined : [],
          };
          current.children.push(child);
        }
        current = child;
      }
    }

    // Sort children: directories first, then files, both alphabetically
    const sortChildren = (node: TreeNode) => {
      if (node.children) {
        node.children.sort((a, b) => {
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          return a.name.localeCompare(b.name);
        });
        node.children.forEach(sortChildren);
      }
    };
    sortChildren(rootNode);

    return rootNode;
  }, []);

  // Helper to get parent directories for a file path
  const getParentDirs = (filePath: string, root: string, browseDir: string): string[] => {
    const dirs: string[] = [];
    const browsePath = `${root}/${browseDir}`;
    if (!filePath.startsWith(browsePath)) return dirs;

    let current = filePath;
    while (current !== browsePath && current.includes('/')) {
      current = current.substring(0, current.lastIndexOf('/'));
      if (current.startsWith(browsePath)) {
        dirs.push(current);
      }
    }
    return dirs;
  };

  // Function to load/refresh file tree
  const loadFileTree = useCallback(async (root: string) => {
    if (isTauriClient) {
      const { invoke } = await import('@tauri-apps/api/core');
      const mdFiles: string[] = await invoke('list_markdown_files', { root });
      setTree(buildTree(mdFiles, root, browseRoot));
    } else {
      // Browser fallback
      const mockFiles = [
        `${root}/claude/agents/housekeeping/agent.md`,
        `${root}/claude/agents/housekeeping/KNOWLEDGE.md`,
        `${root}/claude/agents/housekeeping/WORKLOG.md`,
        `${root}/claude/workstreams/housekeeping/KNOWLEDGE.md`,
        `${root}/claude/principals/jordan/INSTRUCTIONS.md`,
        `${root}/claude/docs/guides/getting-started.md`,
      ];
      setTree(buildTree(mockFiles, root, browseRoot));
    }
  }, [isTauriClient, buildTree, browseRoot]);

  // Load files on mount (wait for isTauriClient to be determined)
  useEffect(() => {
    // Wait until we know if we're in Tauri or browser
    if (isTauriClient === null) return;

    async function loadFiles() {
      try {
        const root = await getProjectRoot();
        setProjectRoot(root);

        // Initialize expanded dirs with the browse root path
        const initialExpanded = new Set([`${root}/${browseRoot}`]);

        // If we have an initial file, expand its parent directories
        if (initialFile) {
          const fullPath = initialFile.startsWith('/') ? initialFile : `${root}/${initialFile}`;
          setSelectedFile(fullPath);
          getParentDirs(fullPath, root, browseRoot).forEach(dir => initialExpanded.add(dir));
        }

        setExpandedDirs(initialExpanded);
        await loadFileTree(root);
      } catch (err) {
        console.error('Failed to load files:', err);
      } finally {
        setLoading(false);
      }
    }

    loadFiles();
  }, [buildTree, initialFile, browseRoot, isTauriClient, loadFileTree]);

  // Load file content when selected
  useEffect(() => {
    async function loadContent() {
      if (!selectedFile) {
        setContent('');
        setEditContent('');
        return;
      }

      try {
        const fileContent = await readFile(selectedFile);
        setContent(fileContent);
        setEditContent(fileContent);
        setHasUnsavedChanges(false);
      } catch (err) {
        console.error('Failed to read file:', err);
        setContent(`# Error\n\nFailed to read file: ${selectedFile}\n\n${err}`);
        setEditContent('');
      }
    }

    loadContent();
  }, [selectedFile]);

  // Track unsaved changes
  useEffect(() => {
    setHasUnsavedChanges(editContent !== content && isEditing);
  }, [editContent, content, isEditing]);

  const handleSave = useCallback(async () => {
    if (!selectedFile || !isTauriClient) return;

    setIsSaving(true);
    try {
      await writeFile(selectedFile, editContent);
      setContent(editContent);
      setHasUnsavedChanges(false);
    } catch (err) {
      console.error('Failed to save file:', err);
      alert(`Failed to save: ${err}`);
    } finally {
      setIsSaving(false);
    }
  }, [selectedFile, editContent]);

  const handleToggleEdit = async () => {
    if (isEditing && hasUnsavedChanges) {
      // Ask if they want to save
      const wantToSave = confirm('You have unsaved changes. Save them?\n\nOK = Save changes\nCancel = Continue without saving');

      if (wantToSave) {
        // Save first, then switch
        if (selectedFile && isTauriClient) {
          setIsSaving(true);
          try {
            await writeFile(selectedFile, editContent);
            setContent(editContent);
            setHasUnsavedChanges(false);
          } catch (err) {
            console.error('Failed to save file:', err);
            alert(`Failed to save: ${err}`);
            return; // Don't switch if save failed
          } finally {
            setIsSaving(false);
          }
        }
      } else {
        // Ask if they want to discard
        const wantToDiscard = confirm('Discard changes?\n\nOK = Discard changes\nCancel = Stay in edit mode');
        if (!wantToDiscard) {
          return; // Stay in edit mode
        }
        // Discard changes
        setEditContent(content);
      }
    }
    setIsEditing(!isEditing);
    setHasUnsavedChanges(false);
  };

  const toggleDir = (path: string) => {
    setExpandedDirs((prev) => {
      const next = new Set(prev);
      if (next.has(path)) {
        next.delete(path);
      } else {
        next.add(path);
      }
      return next;
    });
  };

  const selectFile = (path: string) => {
    if (hasUnsavedChanges && !confirm('Unsaved changes will be lost. Continue?')) {
      return;
    }
    setSelectedFile(path);
    setIsEditing(false);
  };

  const toggleFavorite = (path: string) => {
    if (favorites.includes(path)) {
      setFavorites(favorites.filter((f) => f !== path));
    } else {
      setFavorites([...favorites, path]);
    }
  };

  const isFavorite = selectedFile ? favorites.includes(selectedFile) : false;

  // Handle root directory change - with delayed click to allow double-click
  const handleChangeRootClick = () => {
    // Clear any existing timer
    if (clickTimerRef.current) {
      clearTimeout(clickTimerRef.current);
    }
    // Set a timer - if no double-click within 250ms, trigger single-click action
    clickTimerRef.current = setTimeout(async () => {
      if (!isTauriClient) {
        alert('Directory picker requires Tauri mode');
        return;
      }

      try {
        const { open } = await import('@tauri-apps/plugin-dialog');
        const selected = await open({
          directory: true,
          defaultPath: `${projectRoot}/${browseRoot}`,
          title: 'Select browse root directory',
        });

        if (selected && typeof selected === 'string') {
          // Make relative to project root
          const relativePath = selected.replace(projectRoot + '/', '');
          setBrowseRoot(relativePath);
          setExpandedDirs(new Set([selected]));
        }
      } catch (err) {
        console.error('Failed to open directory picker:', err);
      }
    }, 250);
  };

  // Handle text selection for comment feature (Edit mode)
  const handleTextSelection = (e: React.MouseEvent) => {
    if (!isEditing) return;

    const textarea = textareaRef.current;
    if (!textarea) return;

    // Use setTimeout to ensure selection is captured after mouseup
    setTimeout(() => {
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;
      console.log('Edit selection:', { start, end, hasSelection: start !== end });
      if (start !== end) {
        const selectedText = editContent.substring(start, end);
        if (selectedText.trim()) {
          const selData = { text: selectedText, start, end };
          console.log('Setting popup for edit mode:', selData);
          // Store in ref for reliable access
          selectionDataRef.current = selData;
          setSelectionPopup({
            x: e.clientX,
            y: e.clientY - 40, // Position above cursor
            ...selData,
          });
        }
      }
    }, 10);
  };

  // Handle text selection for comment feature (Preview mode)
  const handlePreviewSelection = (e: React.MouseEvent) => {
    // Use setTimeout to ensure selection is captured after mouseup
    setTimeout(() => {
      const selection = window.getSelection();
      const selectedText = selection?.toString().trim() || '';
      console.log('Preview selection:', { selectedText, hasSelection: !!selectedText });
      if (selectedText) {
        // Find the text in the content to get start/end positions
        const start = content.indexOf(selectedText);
        console.log('Found in content at:', start);
        if (start !== -1) {
          const selData = { text: selectedText, start, end: start + selectedText.length };
          console.log('Setting popup for preview mode:', selData);
          // Store in ref for reliable access
          selectionDataRef.current = selData;
          setSelectionPopup({
            x: e.clientX,
            y: e.clientY - 40,
            ...selData,
          });
        }
      }
    }, 10);
  };

  // Track if there's a text selection (for Insert > Comment menu state)
  useEffect(() => {
    const checkSelection = () => {
      if (isEditing && textareaRef.current) {
        const textarea = textareaRef.current;
        const hasSelection = textarea.selectionStart !== textarea.selectionEnd;
        setHasTextSelection(hasSelection);
      } else if (!isEditing) {
        const selection = window.getSelection();
        const hasSelection = !!(selection && selection.toString().trim());
        setHasTextSelection(hasSelection);
      }
    };

    document.addEventListener('selectionchange', checkSelection);
    return () => document.removeEventListener('selectionchange', checkSelection);
  }, [isEditing]);

  // Handle Insert > Comment from menu - adds comment block after selected text
  // Format: keeps original text, adds quoted selection + empty marker below
  const handleInsertCommentFromMenu = () => {
    setShowInsertMenu(false);

    // Get principal name (use stored or default to 'user')
    const principal = principalName.trim().toLowerCase() || 'user';
    const emptyMarker = `[(${principal}) ]`;

    // Check if we have selection data from Preview mode
    const selData = selectionDataRef.current;

    if (isEditing && textareaRef.current) {
      const textarea = textareaRef.current;
      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;

      if (start !== end) {
        // Has selection - insert comment block AFTER selection
        const selectedText = editContent.substring(start, end);
        const quotedLine = `[(${principal}) ${selectedText}]`;
        const commentBlock = `\n${quotedLine}\n${emptyMarker}`;
        const newContent = editContent.substring(0, end) + commentBlock + editContent.substring(end);
        setEditContent(newContent);
        setHasUnsavedChanges(true);

        // Position cursor inside the empty marker (before the ])
        setTimeout(() => {
          textarea.focus();
          const newPos = end + commentBlock.length - 1;
          textarea.setSelectionRange(newPos, newPos);
        }, 0);
      } else {
        // No selection - insert empty marker at cursor
        const newContent = editContent.substring(0, start) + emptyMarker + editContent.substring(start);
        setEditContent(newContent);
        setHasUnsavedChanges(true);

        setTimeout(() => {
          textarea.focus();
          const newPos = start + emptyMarker.length - 1;
          textarea.setSelectionRange(newPos, newPos);
        }, 0);
      }
    } else if (selData && selData.text) {
      // Preview mode with selection - insert comment block AFTER selection
      const quotedLine = `[(${principal}) ${selData.text}]`;
      const commentBlock = `\n${quotedLine}\n${emptyMarker}`;
      const newContent = content.substring(0, selData.end) + commentBlock + content.substring(selData.end);

      setIsEditing(true);
      setEditContent(newContent);
      setHasUnsavedChanges(true);
      selectionDataRef.current = null;

      // Position cursor inside the empty marker after edit mode activates
      setTimeout(() => {
        if (textareaRef.current) {
          textareaRef.current.focus();
          const newPos = selData.end + commentBlock.length - 1;
          textareaRef.current.setSelectionRange(newPos, newPos);
        }
      }, 100);
    } else {
      // No selection - insert at end
      setIsEditing(true);
      const newContent = content + '\n' + emptyMarker;
      setEditContent(newContent);
      setHasUnsavedChanges(true);

      setTimeout(() => {
        if (textareaRef.current) {
          textareaRef.current.focus();
          const newPos = newContent.length - 1;
          textareaRef.current.setSelectionRange(newPos, newPos);
        }
      }, 100);
    }
  };

  // Handle Insert > Image from menu
  const handleInsertImage = async () => {
    setShowInsertMenu(false);
    if (!isTauriClient) {
      alert('Image insertion requires Tauri mode');
      return;
    }

    try {
      const { open } = await import('@tauri-apps/plugin-dialog');
      const selected = await open({
        multiple: false,
        filters: [{ name: 'Images', extensions: ['png', 'svg'] }],
        title: 'Select image to insert',
      });

      if (selected && typeof selected === 'string') {
        setPendingImagePath(selected);
        setImageAltText('');
        setShowAltTextModal(true);
      }
    } catch (err) {
      console.error('Failed to open file picker:', err);
      alert(`Failed to open file picker: ${err}`);
    }
  };

  // Handle Insert > Document reference from menu
  const handleInsertDocumentRef = async () => {
    setShowInsertMenu(false);
    if (!isTauriClient) {
      alert('Document reference requires Tauri mode');
      return;
    }

    try {
      const { open } = await import('@tauri-apps/plugin-dialog');
      const selected = await open({
        multiple: false,
        filters: [{ name: 'Documents', extensions: ['md', 'png', 'svg'] }],
        defaultPath: projectRoot,
        title: 'Select document to reference',
      });

      if (selected && typeof selected === 'string') {
        // Make path relative to project root
        const relativePath = selected.startsWith(projectRoot)
          ? selected.replace(projectRoot + '/', '')
          : selected;
        const filename = selected.split('/').pop() || relativePath;
        const linkMarkdown = `[${filename}](/${relativePath})`;

        // Insert at cursor position
        if (isEditing && textareaRef.current) {
          const textarea = textareaRef.current;
          const pos = textarea.selectionStart;
          const newContent = editContent.substring(0, pos) + linkMarkdown + editContent.substring(pos);
          setEditContent(newContent);
          setHasUnsavedChanges(true);
        } else {
          const newContent = content + '\n' + linkMarkdown;
          setEditContent(newContent);
          setContent(newContent);
          setHasUnsavedChanges(true);
          setIsEditing(true);
        }
      }
    } catch (err) {
      console.error('Failed to select document:', err);
      alert(`Failed to select document: ${err}`);
    }
  };

  // Complete image insertion after alt-text is provided
  const completeImageInsertion = async () => {
    if (!pendingImagePath || !isTauriClient) return;

    try {
      const { copyFile } = await import('@tauri-apps/plugin-fs');
      const { Command } = await import('@tauri-apps/plugin-shell');

      // Extract filename from path
      const filename = pendingImagePath.split('/').pop() || 'image.png';

      // Create target directory
      const targetDir = `${projectRoot}/claude/assets/images`;
      await Command.create('mkdir', ['-p', targetDir]).execute();

      // Generate unique filename if needed
      let targetFilename = filename;
      let targetPath = `${targetDir}/${targetFilename}`;

      // Check if file exists and generate unique name if needed
      try {
        const { stat } = await import('@tauri-apps/plugin-fs');
        await stat(targetPath);
        // File exists, add timestamp
        const ext = filename.includes('.') ? `.${filename.split('.').pop()}` : '';
        const base = filename.replace(ext, '');
        const timestamp = Date.now();
        targetFilename = `${base}-${timestamp}${ext}`;
        targetPath = `${targetDir}/${targetFilename}`;
      } catch {
        // File doesn't exist, use original name
      }

      // Copy file to assets directory
      await copyFile(pendingImagePath, targetPath);

      // Create absolute path from project root
      const absolutePath = `/claude/assets/images/${targetFilename}`;

      // Build markdown image syntax
      const altText = imageAltText.trim() || filename.replace(/\.(png|svg)$/i, '');
      const imageMarkdown = `![${altText}](${absolutePath})`;

      // Insert at cursor position (or end if no position)
      if (isEditing && textareaRef.current) {
        const textarea = textareaRef.current;
        const pos = textarea.selectionStart;
        const newContent = editContent.substring(0, pos) + imageMarkdown + editContent.substring(pos);
        setEditContent(newContent);
        setHasUnsavedChanges(true);
      } else {
        // Switch to edit mode and append
        const newContent = content + '\n' + imageMarkdown;
        setEditContent(newContent);
        setContent(newContent);
        setHasUnsavedChanges(true);
        setIsEditing(true);
      }

      // Reset modal state
      setShowAltTextModal(false);
      setPendingImagePath(null);
      setImageAltText('');
    } catch (err) {
      console.error('Failed to insert image:', err);
      alert(`Failed to insert image: ${err}`);
    }
  };

  // Handle Insert > Web Link from menu
  const handleInsertWebLink = () => {
    setShowInsertMenu(false);
    setWebLinkUrl('');
    setWebLinkText('');
    setShowWebLinkModal(true);
  };

  // Complete web link insertion after URL is provided
  const completeWebLinkInsertion = () => {
    if (!webLinkUrl.trim()) return;

    const url = webLinkUrl.trim();
    const text = webLinkText.trim() || url;
    const linkMarkdown = `[${text}](${url})`;

    if (isEditing && textareaRef.current) {
      const textarea = textareaRef.current;
      const pos = textarea.selectionStart;
      const newContent = editContent.substring(0, pos) + linkMarkdown + editContent.substring(pos);
      setEditContent(newContent);
      setHasUnsavedChanges(true);
    } else {
      const newContent = content + '\n' + linkMarkdown;
      setEditContent(newContent);
      setContent(newContent);
      setHasUnsavedChanges(true);
      setIsEditing(true);
    }

    setShowWebLinkModal(false);
  };

  // Handle Insert > Object Reference from menu
  const handleInsertObjectRef = (type: 'bug' | 'request') => {
    setShowInsertMenu(false);
    setObjectRefId('');
    setShowObjectRefModal(type);
  };

  // Complete object reference insertion after ID is provided
  const completeObjectRefInsertion = () => {
    if (!objectRefId.trim()) return;

    const refId = objectRefId.trim().toUpperCase();
    const refMarkdown = `[${refId}]`;

    if (isEditing && textareaRef.current) {
      const textarea = textareaRef.current;
      const pos = textarea.selectionStart;
      const newContent = editContent.substring(0, pos) + refMarkdown + editContent.substring(pos);
      setEditContent(newContent);
      setHasUnsavedChanges(true);
    } else {
      const newContent = content + '\n' + refMarkdown;
      setEditContent(newContent);
      setContent(newContent);
      setHasUnsavedChanges(true);
      setIsEditing(true);
    }

    setShowObjectRefModal(null);
  };

  // Insert comment with the form data
  const doInsertComment = () => {
    const selData = selectionDataRef.current;
    if (!selData || !principalName.trim() || !commentInput.trim()) {
      console.log('Missing data for comment insertion');
      return;
    }

    const { text: selectedText, start, end } = selData;
    const principal = principalName.trim().toLowerCase();
    const commentBlock = `[(${principal}) ${selectedText}]\n[(${principal}) ${commentInput.trim()}]`;
    console.log('Creating comment block:', commentBlock);

    const baseContent = isEditing ? editContent : content;
    // Keep original text and insert comment block AFTER the selection
    const newContent = baseContent.substring(0, end) + '\n' + commentBlock + baseContent.substring(end);

    setEditContent(newContent);
    setContent(newContent);
    setHasUnsavedChanges(true);
    setIsEditing(true);
    setSelectionPopup(null);
    setShowCommentForm(false);
    setCommentInput('');
    selectionDataRef.current = null;
    console.log('Comment inserted!');
  };

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 's' && isEditing) {
        e.preventDefault();
        handleSave();
      }
      if ((e.metaKey || e.ctrlKey) && e.key === 'e') {
        e.preventDefault();
        handleToggleEdit();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isEditing, handleSave]);

  // Close popup when clicking outside (with delay to allow button click)
  useEffect(() => {
    if (!selectionPopup) return;

    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      // Don't close if clicking the popup itself
      if (target.closest('[data-comment-popup]')) return;
      setSelectionPopup(null);
      setShowCommentForm(false);
      setCommentInput('');
    };

    // Add listener after a short delay to avoid immediate close
    const timer = setTimeout(() => {
      document.addEventListener('mousedown', handleClickOutside);
    }, 100);

    return () => {
      clearTimeout(timer);
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [selectionPopup]);

  // Close create menu when clicking outside
  useEffect(() => {
    if (!showCreateMenu) return;

    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      if (target.closest('[data-create-menu]')) return;
      setShowCreateMenu(false);
    };

    const timer = setTimeout(() => {
      document.addEventListener('mousedown', handleClickOutside);
    }, 100);

    return () => {
      clearTimeout(timer);
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showCreateMenu]);

  // Close insert menu when clicking outside
  useEffect(() => {
    if (!showInsertMenu) return;

    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      if (target.closest('[data-insert-menu]')) return;
      setShowInsertMenu(false);
    };

    const timer = setTimeout(() => {
      document.addEventListener('mousedown', handleClickOutside);
    }, 100);

    return () => {
      clearTimeout(timer);
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [showInsertMenu]);

  // Helper to get next number for a document type (REQUEST, OBSERVE, etc.)
  const getNextDocNumber = async (prefix: string): Promise<number> => {
    if (!isTauriClient) return 1;

    try {
      const { invoke } = await import('@tauri-apps/api/core');
      // List all files to find highest number for this prefix
      const files: string[] = await invoke('list_markdown_files', { root: projectRoot });
      let highest = 0;

      const pattern = new RegExp(`${prefix}-[^-]+-(\\d+)-`);
      for (const f of files) {
        const match = f.match(pattern);
        if (match) {
          const num = parseInt(match[1], 10);
          if (num > highest) highest = num;
        }
      }

      return highest + 1;
    } catch (err) {
      console.error(`Failed to get next ${prefix} number:`, err);
      return 1;
    }
  };

  // Slugify helper
  const slugify = (text: string): string => {
    return text.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '').substring(0, 50);
  };

  // Helper to create directory using shell (avoids fs plugin scope issues)
  const ensureDirectory = async (dirPath: string) => {
    const { Command } = await import('@tauri-apps/plugin-shell');
    await Command.create('mkdir', ['-p', dirPath]).execute();
  };

  // Helper to format timestamp with timezone
  const formatTimestamp = (date: Date): string => {
    const dateStr = date.toISOString().split('T')[0];
    const timeStr = date.toTimeString().slice(0, 5);
    // Get timezone abbreviation
    const tzMatch = date.toTimeString().match(/\(([^)]+)\)/);
    const tz = tzMatch ? tzMatch[1] : Intl.DateTimeFormat().resolvedOptions().timeZone;
    // Try to get short timezone name
    const shortTz = tz.includes(' ')
      ? tz.split(' ').map(w => w[0]).join('') // e.g., "Singapore Standard Time" -> "SST"
      : tz;
    return `${dateStr} ${timeStr} ${shortTz}`;
  };

  // Create a new REQUEST document
  const handleCreateRequest = async () => {
    if (!createAgentName.trim() || !createSummary.trim() || !principalName.trim()) {
      alert('Please fill in all required fields: Agent, Summary, and your name');
      return;
    }

    setIsCreating(true);
    try {
      const number = await getNextDocNumber('REQUEST');
      const numberPadded = String(number).padStart(4, '0');
      const slug = slugify(createSummary);
      const principal = principalName.trim().toLowerCase();
      const now = new Date();
      const timestamp = formatTimestamp(now);

      const filename = `REQUEST-${principal}-${numberPadded}-${createAgentName.trim()}-${slug}.md`;
      const dirPath = `${projectRoot}/claude/principals/${principal}/requests`;
      const filePath = `${dirPath}/${filename}`;

      const content = `# REQUEST-${principal}-${numberPadded}-${createAgentName.trim()}-${slug}

**Requested By:** principal:${principal}

**Assigned To:** ${createAgentName.trim()}

**Status:** Open

**Priority:** ${createPriority}

**Created:** ${timestamp}

**Updated:** ${timestamp}

## Summary

${createSummary}

## Details

<!-- Detailed description of what you're requesting -->

## Acceptance Criteria

<!-- How will we know when this is complete? -->
- [ ] Criteria 1
- [ ] Criteria 2

## Notes

<!-- Any additional context, constraints, or preferences -->

---

## Activity Log

### ${timestamp} - Created
- Request created by principal:${principal}
`;

      if (isTauriClient) {
        const { invoke } = await import('@tauri-apps/api/core');

        // Create directory using shell (avoids fs plugin scope issues)
        await ensureDirectory(dirPath);
        await invoke('write_file', { path: filePath, content });
      }

      // Reset form and close modal
      setCreateAgentName('');
      setCreateSummary('');
      setCreatePriority('Normal');
      setShowCreateModal(null);

      // Expand tree to show the new file
      setExpandedDirs(prev => {
        const next = new Set(prev);
        let current = dirPath;
        while (current.includes('/')) {
          next.add(current);
          current = current.substring(0, current.lastIndexOf('/'));
        }
        return next;
      });

      // Select the new file and switch to edit mode
      setSelectedFile(filePath);
      setContent(content);
      setEditContent(content);
      setIsEditing(true);

      // Refresh file tree
      await loadFileTree(projectRoot);
    } catch (err) {
      console.error('Failed to create request:', err);
      alert(`Failed to create request: ${err}`);
    } finally {
      setIsCreating(false);
    }
  };

  // Create a Note document
  const handleCreateNote = async () => {
    if (!principalName.trim() || !createSummary.trim()) {
      alert('Please enter your name and what this is about');
      return;
    }

    setIsCreating(true);
    try {
      const principal = principalName.trim().toLowerCase();
      const now = new Date();
      const fileTimestamp = now.toISOString().slice(0, 16).replace(/[-:T]/g, '').replace(/(\d{8})(\d{4})/, '$1-$2');
      const slug = slugify(createSummary);
      const filename = `${fileTimestamp}-${slug}.md`;
      const dirPath = `${projectRoot}/claude/principals/${principal}/notes`;
      const filePath = `${dirPath}/${filename}`;

      const timestamp = formatTimestamp(now);

      const content = `# ${createSummary}

**Author:** ${principal}

**Created:** ${timestamp}

`;

      if (isTauriClient) {
        const { invoke } = await import('@tauri-apps/api/core');

        // Create directory using shell (avoids fs plugin scope issues)
        await ensureDirectory(dirPath);
        await invoke('write_file', { path: filePath, content });
      }

      setShowCreateModal(null);
      setCreateSummary('');

      // Expand tree to show the new file
      setExpandedDirs(prev => {
        const next = new Set(prev);
        let current = dirPath;
        while (current.includes('/')) {
          next.add(current);
          current = current.substring(0, current.lastIndexOf('/'));
        }
        return next;
      });

      // Select the new file and switch to edit mode
      setSelectedFile(filePath);
      setContent(content);
      setEditContent(content);
      setIsEditing(true);

      // Refresh file tree
      await loadFileTree(projectRoot);
    } catch (err) {
      console.error('Failed to create note:', err);
      alert(`Failed to create note: ${err}`);
    } finally {
      setIsCreating(false);
    }
  };

  // Create a new OBSERVE document
  const handleCreateObserve = async () => {
    if (!createSummary.trim() || !principalName.trim()) {
      alert('Please fill in all required fields: Summary and your name');
      return;
    }

    setIsCreating(true);
    try {
      const number = await getNextDocNumber('OBSERVE');
      const numberPadded = String(number).padStart(4, '0');
      const slug = slugify(createSummary);
      const principal = principalName.trim().toLowerCase();
      const now = new Date();
      const timestamp = formatTimestamp(now);

      const filename = `OBSERVE-${principal}-${numberPadded}-${slug}.md`;
      const dirPath = `${projectRoot}/claude/principals/${principal}/observations`;
      const filePath = `${dirPath}/${filename}`;

      const content = `# OBSERVE-${principal}-${numberPadded}-${slug}

**Observed By:** principal:${principal}

**Status:** Open

**Created:** ${timestamp}

**Updated:** ${timestamp}

## Summary

${createSummary}

## Observation

${createObservation || '<!-- What did you observe? Describe what you noticed. -->'}

## Context

<!-- Where did you observe this? What were you doing? -->

## Potential Impact

<!-- Why might this matter? What could happen if not addressed? -->

## Related

<!-- Links to related files, requests, or observations -->

---

## Notes

### ${timestamp} - Created
- Observation recorded by principal:${principal}
`;

      if (isTauriClient) {
        const { invoke } = await import('@tauri-apps/api/core');

        // Create directory using shell (avoids fs plugin scope issues)
        await ensureDirectory(dirPath);
        await invoke('write_file', { path: filePath, content });
      }

      // Reset form and close modal
      setCreateSummary('');
      setCreateObservation('');
      setShowCreateModal(null);

      // Expand tree to show the new file
      setExpandedDirs(prev => {
        const next = new Set(prev);
        let current = dirPath;
        while (current.includes('/')) {
          next.add(current);
          current = current.substring(0, current.lastIndexOf('/'));
        }
        return next;
      });

      // Select the new file and switch to edit mode
      setSelectedFile(filePath);
      setContent(content);
      setEditContent(content);
      setIsEditing(true);

      // Refresh file tree
      await loadFileTree(projectRoot);
    } catch (err) {
      console.error('Failed to create observation:', err);
      alert(`Failed to create observation: ${err}`);
    } finally {
      setIsCreating(false);
    }
  };

  // Create document from template
  const handleCreateFromTemplate = async (templateId: string) => {
    if (!principalName.trim()) {
      alert('Please set your name in Settings first');
      return;
    }

    setIsCreating(true);
    try {
      const principal = principalName.trim().toLowerCase();
      const now = new Date();
      const timestamp = formatTimestamp(now);
      const fileTimestamp = now.toISOString().slice(0, 16).replace(/[-:T]/g, '').replace(/(\d{8})(\d{4})/, '$1-$2');

      let content = '';
      let filename = '';
      const dirPath = `${projectRoot}/claude/principals/${principal}/notes`;

      switch (templateId) {
        case 'bug-report':
          filename = `BUG-${fileTimestamp}.md`;
          content = `# Bug Report

**Reporter:** ${principal}
**Created:** ${timestamp}
**Status:** Open

## Summary

<!-- Brief description of the bug -->

## Steps to Reproduce

1. Step one
2. Step two
3. Step three

## Expected Behavior

<!-- What should happen -->

## Actual Behavior

<!-- What actually happens -->

## Environment

- OS:
- Version:

## Additional Context

<!-- Screenshots, logs, etc. -->
`;
          break;

        case 'meeting-notes':
          filename = `meeting-${fileTimestamp}.md`;
          content = `# Meeting Notes

**Date:** ${timestamp}
**Attendees:** ${principal}

## Agenda

1. Topic one
2. Topic two

## Discussion

### Topic One

<!-- Notes -->

### Topic Two

<!-- Notes -->

## Action Items

- [ ] Action item 1 - @owner
- [ ] Action item 2 - @owner

## Next Meeting

<!-- Date/time for follow-up -->
`;
          break;

        case 'decision-record':
          filename = `decision-${fileTimestamp}.md`;
          content = `# Decision Record

**Author:** ${principal}
**Date:** ${timestamp}
**Status:** Proposed

## Context

<!-- What is the issue that we're seeing that motivates this decision? -->

## Decision

<!-- What is the change that we're proposing and/or doing? -->

## Consequences

<!-- What becomes easier or more difficult to do because of this change? -->

## Alternatives Considered

1. **Alternative A** - Why not chosen
2. **Alternative B** - Why not chosen
`;
          break;

        default:
          throw new Error(`Unknown template: ${templateId}`);
      }

      const filePath = `${dirPath}/${filename}`;

      if (isTauriClient) {
        const { invoke } = await import('@tauri-apps/api/core');
        await ensureDirectory(dirPath);
        await invoke('write_file', { path: filePath, content });
      }

      setShowTemplateModal(false);

      // Expand tree to show the new file
      setExpandedDirs(prev => {
        const next = new Set(prev);
        let current = dirPath;
        while (current.includes('/')) {
          next.add(current);
          current = current.substring(0, current.lastIndexOf('/'));
        }
        return next;
      });

      // Select the new file and switch to edit mode
      setSelectedFile(filePath);
      setContent(content);
      setEditContent(content);
      setIsEditing(true);

      // Refresh file tree
      await loadFileTree(projectRoot);
    } catch (err) {
      console.error('Failed to create from template:', err);
      alert(`Failed to create: ${err}`);
    } finally {
      setIsCreating(false);
    }
  };

  // Delete the currently selected file
  const handleDelete = async () => {
    if (!selectedFile || !isTauriClient) return;

    const fileName = selectedFile.split('/').pop();
    if (!confirm(`Delete "${fileName}"?\n\nThis cannot be undone.`)) return;

    try {
      const { remove } = await import('@tauri-apps/plugin-fs');
      await remove(selectedFile);

      // Remove from favorites if it was favorited
      if (favorites.includes(selectedFile)) {
        setFavorites(favorites.filter(f => f !== selectedFile));
      }

      // Clear selection
      setSelectedFile(null);
      setContent('');
      setEditContent('');

      // Refresh file tree
      await loadFileTree(projectRoot);
    } catch (err) {
      console.error('Failed to delete file:', err);
      alert(`Failed to delete: ${err}`);
    }
  };

  // Open file in external editor
  const handleOpenInEditor = async () => {
    if (!selectedFile || !isTauriClient) return;

    try {
      const { Command } = await import('@tauri-apps/plugin-shell');
      // Try VS Code first, fall back to system default
      try {
        await Command.create('code', [selectedFile]).execute();
      } catch {
        // Fall back to 'open' on macOS
        await Command.create('open', [selectedFile]).execute();
      }
    } catch (err) {
      console.error('Failed to open in editor:', err);
      alert(`Failed to open in editor: ${err}`);
    }
  };

  // Copy icon SVG
  const CopyIcon = () => (
    <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
    </svg>
  );

  // Copy to clipboard helper
  const copyToClipboard = (text: string, e?: React.MouseEvent) => {
    e?.stopPropagation();
    navigator.clipboard.writeText(text);
  };

  // Copy button component - copies absolute path
  const CopyButton = ({ path }: { path: string }) => {
    return (
      <button
        onClick={(e) => copyToClipboard(path, e)}
        className="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-gray-600 p-0.5 rounded hover:bg-gray-200 transition-colors"
        title={`Copy path`}
      >
        <CopyIcon />
      </button>
    );
  };

  // Render tree node
  const renderTreeNode = (node: TreeNode, depth: number = 0) => {
    const isExpanded = expandedDirs.has(node.path);
    const isSelected = selectedFile === node.path;
    const indent = depth * 12;

    if (node.isDirectory) {
      const isDirFavorite = favorites.includes(node.path);
      return (
        <div key={node.path} className="group">
          <div
            className="w-full text-left py-0.5 hover:bg-gray-100 rounded flex items-center gap-1 text-sm"
            style={{ paddingLeft: indent + 4 }}
          >
            <button
              onClick={() => toggleDir(node.path)}
              className="flex items-center gap-1 flex-1 min-w-0"
              title={node.path}
            >
              <span className="text-xs text-gray-400 w-3 flex-shrink-0">{isExpanded ? '▼' : '▶'}</span>
              <span className="truncate">{node.name}/</span>
            </button>
            <button
              onClick={(e) => { e.stopPropagation(); toggleFavorite(node.path); }}
              className={`opacity-0 group-hover:opacity-100 p-0.5 transition-colors ${
                isDirFavorite ? 'text-yellow-500 opacity-100' : 'text-gray-300 hover:text-yellow-400'
              }`}
              title={isDirFavorite ? 'Remove from favorites' : 'Add to favorites'}
            >
              ★
            </button>
            <CopyButton path={node.path} />
          </div>
          {isExpanded && node.children && (
            <div>
              {node.children.map((child) => renderTreeNode(child, depth + 1))}
            </div>
          )}
        </div>
      );
    }

    return (
      <div key={node.path} className="group flex items-center">
        <button
          onClick={() => selectFile(node.path)}
          className={`flex-1 text-left py-0.5 rounded text-sm transition-colors ${
            isSelected ? 'bg-agency-100 text-agency-700' : 'hover:bg-gray-100 text-gray-600'
          }`}
          style={{ paddingLeft: indent + 16 }}
          title={node.path}
        >
          {node.name}
        </button>
        <CopyButton path={node.path} />
      </div>
    );
  };

  return (
    <div ref={containerRef} className="flex h-[calc(100vh-8rem)]">
      {/* File Tree */}
      <div
        className="bg-white rounded-xl border border-gray-200 flex flex-col flex-shrink-0"
        style={{ width: sidebarWidth }}
      >
        {/* Browse Root Selector */}
        <div className="p-3 border-b border-gray-200 group">
          <div className="flex items-center justify-between gap-1">
            <button
              onClick={handleChangeRootClick}
              className="text-left hover:bg-gray-50 transition-colors flex-1 min-w-0"
              title={`${projectRoot}/${browseRoot}`}
            >
              <span className="text-sm font-medium text-gray-700 truncate flex items-center gap-1">
                {browseRoot}/
                <span className="text-xs text-gray-400">▼</span>
              </span>
            </button>
            <div className="flex items-center gap-1 flex-shrink-0">
              {/* Home button - reset to claude/ */}
              {browseRoot !== 'claude' && (
                <button
                  onClick={() => {
                    setBrowseRoot('claude');
                    setExpandedDirs(new Set([`${projectRoot}/claude`]));
                  }}
                  className="text-gray-400 hover:text-agency-600 p-1 rounded hover:bg-gray-100 transition-colors"
                  title="Back to claude/"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                  </svg>
                </button>
              )}
            <button
              onClick={(e) => copyToClipboard(`${projectRoot}/${browseRoot}`, e)}
              className="text-gray-400 hover:text-gray-600 p-1 rounded hover:bg-gray-100 transition-colors"
              title="Copy path"
            >
              <CopyIcon />
            </button>
            </div>
          </div>
          <div className="text-xs text-gray-400 mt-1">
            {isTauriClient ? 'Click to change' : 'Browser mode'}
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-2 font-mono text-xs">
          {loading ? (
            <div className="text-center py-4 text-gray-400">Loading...</div>
          ) : tree && tree.children ? (
            tree.children.map((child) => renderTreeNode(child, 0))
          ) : (
            <div className="text-center py-4 text-gray-400">No files found</div>
          )}
        </div>

        {/* Quick Access - principal directories (always visible when principal is set) */}
        {principalName && (
          <div className="border-t border-gray-200 p-2">
            <div className="text-xs font-medium text-gray-500 mb-1 px-1">Quick Access</div>
            <div className="font-mono text-xs space-y-0.5">
              {[
                { name: `${principalName}/`, path: `${projectRoot}/claude/principals/${principalName.toLowerCase()}`, browseRoot: `claude/principals/${principalName.toLowerCase()}` },
                { name: 'notes/', path: `${projectRoot}/claude/principals/${principalName.toLowerCase()}/notes`, browseRoot: `claude/principals/${principalName.toLowerCase()}/notes` },
                { name: 'requests/', path: `${projectRoot}/claude/principals/${principalName.toLowerCase()}/requests`, browseRoot: `claude/principals/${principalName.toLowerCase()}/requests` },
                { name: 'observations/', path: `${projectRoot}/claude/principals/${principalName.toLowerCase()}/observations`, browseRoot: `claude/principals/${principalName.toLowerCase()}/observations` },
              ].map((item) => (
                <div key={item.path} className="group flex items-center">
                  <button
                    onClick={() => {
                      // Change browse root to this directory
                      setBrowseRoot(item.browseRoot);
                      // Expand this directory
                      setExpandedDirs(new Set([item.path]));
                    }}
                    className="flex-1 text-left px-1 py-1 rounded truncate hover:bg-gray-100 text-gray-600"
                    title={item.path}
                  >
                    {item.name}
                  </button>
                  <button
                    onClick={(e) => copyToClipboard(item.path, e)}
                    className="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-gray-600 p-0.5 rounded hover:bg-gray-200 transition-colors"
                    title="Copy path"
                  >
                    <CopyIcon />
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Favorites - taller to fit 6 items */}
        <div className="border-t border-gray-200 p-2">
          <div className="text-xs font-medium text-gray-500 mb-1 px-1">Favorites</div>
          <div className="h-36 overflow-y-auto font-mono text-xs">
            {favorites.length === 0 ? (
              <div className="text-gray-400 px-1 py-1">No favorites yet</div>
            ) : (
              favorites.map((path) => {
                // Check if this is a directory by seeing if it's in expandedDirs or doesn't end with .md
                const isDir = !path.endsWith('.md');
                const name = path.split('/').pop() || path;

                const handleFavoriteClick = () => {
                  if (isDir) {
                    // Expand to this directory
                    setExpandedDirs(prev => {
                      const next = new Set(prev);
                      // Add this dir and all parents
                      let current = path;
                      while (current.includes('/')) {
                        next.add(current);
                        current = current.substring(0, current.lastIndexOf('/'));
                      }
                      return next;
                    });
                  } else {
                    selectFile(path);
                  }
                };

                return (
                  <div key={path} className="group flex items-center">
                    <button
                      onClick={handleFavoriteClick}
                      className={`flex-1 text-left px-1 py-1 rounded truncate ${
                        selectedFile === path
                          ? 'bg-agency-100 text-agency-700'
                          : 'hover:bg-gray-100 text-gray-600'
                      }`}
                      title={path}
                    >
                      {isDir ? `${name}/` : name}
                    </button>
                    <button
                      onClick={(e) => copyToClipboard(path, e)}
                      className="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-gray-600 p-0.5 rounded hover:bg-gray-200 transition-colors"
                      title="Copy path"
                    >
                      <CopyIcon />
                    </button>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Settings */}
        <div className="border-t border-gray-200 p-2">
          <button
            onClick={() => {
              setSettingsPrincipalName(principalName);
              setShowSettingsModal(true);
            }}
            className="w-full flex items-center gap-2 px-2 py-1.5 text-sm text-gray-600 hover:bg-gray-100 rounded transition-colors"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span>Settings</span>
            {principalName && (
              <span className="ml-auto text-xs text-gray-400">{principalName}</span>
            )}
          </button>
        </div>
      </div>

      {/* Resize Handle */}
      <div
        onMouseDown={handleMouseDown}
        className="w-2 cursor-col-resize flex-shrink-0 group flex items-center justify-center hover:bg-gray-100 transition-colors"
      >
        <div className="w-0.5 h-8 bg-gray-300 group-hover:bg-agency-500 rounded-full transition-colors" />
      </div>

      {/* Content Viewer/Editor */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col relative min-w-0">
        {selectedFile ? (
          <>
            <div className="px-4 py-3 border-b border-gray-200">
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-1 min-w-0 flex-1">
                  <span
                    className="font-mono text-sm text-gray-700 truncate"
                    title={selectedFile}
                  >
                    {selectedFile.split('/').pop()}
                  </span>
                  <button
                    onClick={(e) => copyToClipboard(selectedFile, e)}
                    className="text-gray-400 hover:text-gray-600 p-0.5 rounded hover:bg-gray-200 transition-colors flex-shrink-0"
                    title={`Copy: ${selectedFile}`}
                  >
                    <CopyIcon />
                  </button>
                </div>
                <div className="flex items-center gap-1 flex-shrink-0">
                {/* Create Menu */}
                <div className="relative" data-create-menu>
                  <button
                    onClick={() => setShowCreateMenu(!showCreateMenu)}
                    className="px-2 py-1 text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded flex items-center gap-1"
                    title="Create new document"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    <span>Create</span>
                    <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>
                  {showCreateMenu && (
                    <div className="absolute left-0 top-8 bg-white border border-gray-200 rounded-lg shadow-lg py-1 z-50 min-w-40">
                      <button
                        onClick={() => { setShowCreateMenu(false); setShowCreateModal('request'); }}
                        className="w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
                      >
                        <span className="text-agency-600">REQUEST</span>
                        <span className="text-gray-400 text-xs">Assign task to agent</span>
                      </button>
                      <button
                        onClick={() => { setShowCreateMenu(false); setShowCreateModal('observe'); }}
                        className="w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
                      >
                        <span className="text-yellow-600">OBSERVE</span>
                        <span className="text-gray-400 text-xs">Record observation</span>
                      </button>
                      <div className="border-t border-gray-100 my-1" />
                      <button
                        onClick={() => { setShowCreateMenu(false); setShowCreateModal('note'); }}
                        className="w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
                      >
                        <span className="text-blue-600">NOTE</span>
                        <span className="text-gray-400 text-xs">Personal note</span>
                      </button>
                      <div className="border-t border-gray-100 my-1" />
                      <button
                        onClick={() => { setShowCreateMenu(false); setShowTemplateModal(true); }}
                        className="w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
                      >
                        <span className="text-purple-600">TEMPLATE</span>
                        <span className="text-gray-400 text-xs">From template</span>
                      </button>
                    </div>
                  )}
                </div>
                {/* Insert Menu */}
                <div className="relative" data-insert-menu>
                  <button
                    onClick={() => setShowInsertMenu(!showInsertMenu)}
                    className="px-2 py-1 text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded flex items-center gap-1"
                    title="Insert"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                    <span>Insert</span>
                    <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>
                  {showInsertMenu && (
                    <div className="absolute right-0 top-8 bg-white border border-gray-200 rounded-lg shadow-lg py-1 z-50 min-w-36">
                      <button
                        onClick={handleInsertCommentFromMenu}
                        disabled={!hasTextSelection}
                        className={`w-full text-left px-3 py-2 text-sm flex items-center gap-2 ${
                          hasTextSelection
                            ? 'text-gray-700 hover:bg-gray-100'
                            : 'text-gray-400 cursor-not-allowed'
                        }`}
                        title={hasTextSelection ? 'Add comment to selected text' : 'Select text first'}
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                        </svg>
                        <span>Comment</span>
                        {!hasTextSelection && <span className="text-xs text-gray-400 ml-auto">(select text)</span>}
                      </button>
                      <button
                        onClick={handleInsertImage}
                        disabled={!isTauriClient}
                        className={`w-full text-left px-3 py-2 text-sm flex items-center gap-2 ${
                          isTauriClient
                            ? 'text-gray-700 hover:bg-gray-100'
                            : 'text-gray-400 cursor-not-allowed'
                        }`}
                        title="Insert image from file"
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                        </svg>
                        <span>Image</span>
                      </button>
                      <button
                        onClick={handleInsertDocumentRef}
                        disabled={!isTauriClient}
                        className={`w-full text-left px-3 py-2 text-sm flex items-center gap-2 ${
                          isTauriClient
                            ? 'text-gray-700 hover:bg-gray-100'
                            : 'text-gray-400 cursor-not-allowed'
                        }`}
                        title="Insert reference to document"
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                        <span>Document</span>
                      </button>
                      <button
                        onClick={handleInsertWebLink}
                        className="w-full text-left px-3 py-2 text-sm flex items-center gap-2 text-gray-700 hover:bg-gray-100"
                        title="Insert web link"
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                        </svg>
                        <span>Web Link</span>
                      </button>
                      <div className="border-t border-gray-100 my-1" />
                      <button
                        onClick={() => handleInsertObjectRef('bug')}
                        className="w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
                      >
                        <svg className="w-4 h-4 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                        <span>Bug Reference</span>
                      </button>
                      <button
                        onClick={() => handleInsertObjectRef('request')}
                        className="w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
                      >
                        <svg className="w-4 h-4 text-agency-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                        </svg>
                        <span>Request Reference</span>
                      </button>
                    </div>
                  )}
                </div>
                <button
                  onClick={() => toggleFavorite(selectedFile)}
                  className={`px-2 py-1 text-sm ${
                    isFavorite ? 'text-yellow-500' : 'text-gray-300 hover:text-yellow-400'
                  }`}
                  title={isFavorite ? 'Remove from favorites' : 'Add to favorites'}
                >
                  ★
                </button>
                <button
                  onClick={handleOpenInEditor}
                  disabled={!isTauriClient}
                  className="px-2 py-1 text-sm text-gray-400 hover:text-gray-600"
                  title="Open in external editor"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </button>
                <button
                  onClick={handleDelete}
                  disabled={!isTauriClient}
                  className="px-2 py-1 text-sm text-gray-400 hover:text-red-600"
                  title="Delete file"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
                {isEditing && isTauriClient && (
                  <button
                    onClick={handleSave}
                    disabled={isSaving || !hasUnsavedChanges}
                    className="px-3 py-1 text-sm bg-agency-600 text-white rounded hover:bg-agency-700 disabled:opacity-50"
                  >
                    {isSaving ? 'Saving...' : 'Save'}
                  </button>
                )}
                <button
                  onClick={handleToggleEdit}
                  disabled={!isTauriClient}
                  className={`px-3 py-1 text-sm rounded flex items-center gap-1.5 ${
                    isEditing ? 'bg-gray-200 text-gray-700' : 'bg-gray-100 text-gray-600'
                  } ${!isTauriClient ? 'opacity-50' : ''}`}
                  title="Toggle edit mode (Cmd+E)"
                >
                  {isEditing ? 'Preview' : 'Edit'}
                  <kbd className="text-[10px] bg-gray-300/50 px-1 rounded">⌘E</kbd>
                </button>
                </div>
              </div>
              {isEditing && (
                <div className="text-xs text-gray-400 mt-1">
                  Editing | Cmd+S to save
                </div>
              )}
            </div>
            <div className="flex-1 overflow-y-auto relative">
              {isEditing ? (
                <textarea
                  ref={textareaRef}
                  value={editContent}
                  onChange={(e) => setEditContent(e.target.value)}
                  className="w-full h-full p-4 font-mono text-sm resize-none focus:outline-none bg-gray-50"
                  spellCheck={false}
                />
              ) : (
                <div className="p-4">
                  <article className="prose prose-slate max-w-none prose-sm">
                    <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
                  </article>
                </div>
              )}
              {/* Floating copy button for current file path */}
              <button
                onClick={() => copyToClipboard(selectedFile)}
                className="absolute bottom-4 right-4 bg-white border border-gray-200 rounded-lg shadow-md p-2 text-gray-500 hover:text-gray-700 hover:border-gray-300 transition-colors"
                title={`Copy path: ${selectedFile}`}
              >
                <CopyIcon />
              </button>
            </div>
          </>
        ) : (
          <div className="flex-1 flex flex-col">
            {/* Menu bar for no file selected */}
            <div className="px-4 py-3 border-b border-gray-200">
              <div className="flex items-center justify-between gap-2">
                <span className="font-medium text-gray-700">Create Document</span>
                <span className="text-xs text-gray-400">Select a file from the tree or create a new document</span>
              </div>
            </div>
            {/* Create options grid */}
            <div className="flex-1 flex items-center justify-center">
              <div className="max-w-lg w-full p-6">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {/* REQUEST */}
                  <button
                    onClick={() => setShowCreateModal('request')}
                    className="p-4 bg-white border border-gray-200 rounded-xl hover:border-agency-400 hover:shadow-md transition-all text-left group"
                  >
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-2xl">📋</span>
                      <span className="font-semibold text-agency-600 group-hover:text-agency-700">REQUEST</span>
                    </div>
                    <p className="text-sm text-gray-500">Assign a task to an agent</p>
                  </button>
                  {/* OBSERVE */}
                  <button
                    onClick={() => setShowCreateModal('observe')}
                    className="p-4 bg-white border border-gray-200 rounded-xl hover:border-yellow-400 hover:shadow-md transition-all text-left group"
                  >
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-2xl">👁️</span>
                      <span className="font-semibold text-yellow-600 group-hover:text-yellow-700">OBSERVE</span>
                    </div>
                    <p className="text-sm text-gray-500">Record an observation</p>
                  </button>
                  {/* NOTE */}
                  <button
                    onClick={() => setShowCreateModal('note')}
                    className="p-4 bg-white border border-gray-200 rounded-xl hover:border-blue-400 hover:shadow-md transition-all text-left group"
                  >
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-2xl">📝</span>
                      <span className="font-semibold text-blue-600 group-hover:text-blue-700">NOTE</span>
                    </div>
                    <p className="text-sm text-gray-500">Personal note or memo</p>
                  </button>
                  {/* TEMPLATE */}
                  <button
                    onClick={() => setShowTemplateModal(true)}
                    className="p-4 bg-white border border-gray-200 rounded-xl hover:border-purple-400 hover:shadow-md transition-all text-left group"
                  >
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-2xl">📄</span>
                      <span className="font-semibold text-purple-600 group-hover:text-purple-700">TEMPLATE</span>
                    </div>
                    <p className="text-sm text-gray-500">Bug report, meeting notes, etc.</p>
                  </button>
                </div>
                <p className="text-center text-xs text-gray-400 mt-6">
                  Or select a file from the directory tree on the left
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Selection popup for Comment */}
        {selectionPopup && (
          <div
            data-comment-popup
            className="fixed bg-white border border-gray-200 rounded-lg shadow-lg p-3 z-50 min-w-64"
            style={{ left: selectionPopup.x, top: selectionPopup.y }}
          >
            {!showCommentForm ? (
              <button
                onClick={() => setShowCommentForm(true)}
                className="px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 w-full text-left rounded"
              >
                Comment
              </button>
            ) : (
              <div className="space-y-2">
                <div className="text-xs text-gray-500 truncate max-w-xs">
                  Selected: "{selectionPopup.text.substring(0, 50)}{selectionPopup.text.length > 50 ? '...' : ''}"
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-gray-500 whitespace-nowrap">As:</span>
                  <input
                    type="text"
                    placeholder="your name"
                    className="flex-1 px-2 py-1 text-sm border border-gray-300 rounded focus:outline-none focus:border-agency-500"
                    value={principalName}
                    onChange={(e) => setPrincipalName(e.target.value)}
                  />
                </div>
                <textarea
                  placeholder="Your comment..."
                  className="w-full px-2 py-1 text-sm border border-gray-300 rounded focus:outline-none focus:border-agency-500 min-h-16"
                  value={commentInput}
                  onChange={(e) => setCommentInput(e.target.value)}
                  autoFocus={!!principalName}
                />
                <div className="flex gap-2">
                  <button
                    onClick={doInsertComment}
                    disabled={!commentInput.trim() || (!principalName)}
                    className="flex-1 px-3 py-1 text-sm bg-agency-600 text-white rounded hover:bg-agency-700 disabled:opacity-50"
                  >
                    Insert
                  </button>
                  <button
                    onClick={() => {
                      setSelectionPopup(null);
                      setShowCommentForm(false);
                      setCommentInput('');
                      selectionDataRef.current = null;
                    }}
                    className="px-3 py-1 text-sm bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Create Request Modal */}
      {showCreateModal === 'request' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">New Request</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Your Name</label>
                <input
                  type="text"
                  placeholder="e.g., jordan"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={principalName}
                  onChange={(e) => setPrincipalName(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Assign to Agent *</label>
                <input
                  type="text"
                  placeholder="e.g., housekeeping"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={createAgentName}
                  onChange={(e) => setCreateAgentName(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Summary *</label>
                <input
                  type="text"
                  placeholder="Brief description of the request"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={createSummary}
                  onChange={(e) => setCreateSummary(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Priority</label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={createPriority}
                  onChange={(e) => setCreatePriority(e.target.value as typeof createPriority)}
                >
                  <option value="Low">Low</option>
                  <option value="Normal">Normal</option>
                  <option value="High">High</option>
                  <option value="Critical">Critical</option>
                </select>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={handleCreateRequest}
                disabled={isCreating || !createAgentName.trim() || !createSummary.trim()}
                className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 disabled:opacity-50"
              >
                {isCreating ? 'Creating...' : 'Create Request'}
              </button>
              <button
                onClick={() => { setShowCreateModal(null); setCreateAgentName(''); setCreateSummary(''); }}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create Observe Modal */}
      {showCreateModal === 'observe' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">New Observation</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Your Name</label>
                <input
                  type="text"
                  placeholder="e.g., jordan"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={principalName}
                  onChange={(e) => setPrincipalName(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Summary *</label>
                <input
                  type="text"
                  placeholder="What did you observe?"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={createSummary}
                  onChange={(e) => setCreateSummary(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Details (optional)</label>
                <textarea
                  placeholder="Additional context about what you observed..."
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500 min-h-24"
                  value={createObservation}
                  onChange={(e) => setCreateObservation(e.target.value)}
                />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={handleCreateObserve}
                disabled={isCreating || !createSummary.trim()}
                className="flex-1 px-4 py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 disabled:opacity-50"
              >
                {isCreating ? 'Creating...' : 'Record Observation'}
              </button>
              <button
                onClick={() => { setShowCreateModal(null); setCreateSummary(''); setCreateObservation(''); }}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create Note Modal */}
      {showCreateModal === 'note' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">New Note</h2>
            <div className="space-y-4 mb-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Your Name</label>
                <input
                  type="text"
                  placeholder="e.g., jordan"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={principalName}
                  onChange={(e) => setPrincipalName(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">What is this about? *</label>
                <input
                  type="text"
                  placeholder="e.g., Meeting notes, Project ideas"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={createSummary}
                  onChange={(e) => setCreateSummary(e.target.value)}
                />
              </div>
              <div className="bg-gray-50 rounded-lg p-3 font-mono text-xs text-gray-600 break-all">
                principals/{principalName?.toLowerCase() || '{you}'}/notes/
                {(() => {
                  const now = new Date();
                  const ts = now.toISOString().slice(0, 16).replace(/[-:T]/g, '').replace(/(\d{8})(\d{4})/, '$1-$2');
                  const slug = createSummary.trim() ? slugify(createSummary) : '{summary}';
                  return `${ts}-${slug}.md`;
                })()}
              </div>
            </div>
            <div className="flex gap-3">
              <button
                onClick={handleCreateNote}
                disabled={isCreating || !principalName.trim() || !createSummary.trim()}
                className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
              >
                {isCreating ? 'Creating...' : 'Create Note'}
              </button>
              <button
                onClick={() => { setShowCreateModal(null); setCreateSummary(''); }}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Alt-Text Modal for Image Insertion */}
      {showAltTextModal && pendingImagePath && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Insert Image</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Selected File</label>
                <div className="bg-gray-50 rounded-lg p-3 font-mono text-xs text-gray-600 break-all">
                  {pendingImagePath.split('/').pop()}
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Alt Text (description)</label>
                <input
                  type="text"
                  placeholder="Describe the image for accessibility"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={imageAltText}
                  onChange={(e) => setImageAltText(e.target.value)}
                  autoFocus
                />
                <p className="text-xs text-gray-500 mt-1">This text will be shown if the image fails to load, and used by screen readers.</p>
              </div>
              <div className="bg-gray-50 rounded-lg p-3">
                <div className="text-xs text-gray-500 mb-1">Will be saved to:</div>
                <div className="font-mono text-xs text-gray-600 break-all">
                  /claude/assets/images/{pendingImagePath.split('/').pop()}
                </div>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={completeImageInsertion}
                className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700"
              >
                Insert Image
              </button>
              <button
                onClick={() => {
                  setShowAltTextModal(false);
                  setPendingImagePath(null);
                  setImageAltText('');
                }}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Web Link Modal */}
      {showWebLinkModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Insert Web Link</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">URL *</label>
                <input
                  type="url"
                  placeholder="https://example.com"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={webLinkUrl}
                  onChange={(e) => setWebLinkUrl(e.target.value)}
                  autoFocus
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Link Text (optional)</label>
                <input
                  type="text"
                  placeholder="Click here"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={webLinkText}
                  onChange={(e) => setWebLinkText(e.target.value)}
                />
                <p className="text-xs text-gray-500 mt-1">Leave empty to use the URL as link text</p>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={completeWebLinkInsertion}
                disabled={!webLinkUrl.trim()}
                className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 disabled:opacity-50"
              >
                Insert Link
              </button>
              <button
                onClick={() => setShowWebLinkModal(false)}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Object Reference Modal */}
      {showObjectRefModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Insert {showObjectRefModal === 'bug' ? 'Bug' : 'Request'} Reference
            </h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  {showObjectRefModal === 'bug' ? 'Bug ID' : 'Request ID'} *
                </label>
                <input
                  type="text"
                  placeholder={showObjectRefModal === 'bug' ? 'BUG-0042' : 'REQUEST-jordan-0017'}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500 font-mono"
                  value={objectRefId}
                  onChange={(e) => setObjectRefId(e.target.value)}
                  autoFocus
                />
                <p className="text-xs text-gray-500 mt-1">
                  Enter the full ID (e.g., {showObjectRefModal === 'bug' ? 'BUG-0042' : 'REQUEST-jordan-0017'})
                </p>
              </div>
              <div className="bg-gray-50 rounded-lg p-3">
                <div className="text-xs text-gray-500 mb-1">Will insert:</div>
                <div className="font-mono text-sm text-gray-700">
                  [{objectRefId.trim().toUpperCase() || (showObjectRefModal === 'bug' ? 'BUG-XXXX' : 'REQUEST-XXX-XXXX')}]
                </div>
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={completeObjectRefInsertion}
                disabled={!objectRefId.trim()}
                className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 disabled:opacity-50"
              >
                Insert Reference
              </button>
              <button
                onClick={() => setShowObjectRefModal(null)}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Settings Modal */}
      {showSettingsModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Settings</h2>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Your Name (Principal)</label>
                <input
                  type="text"
                  placeholder="e.g., jordan"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:border-agency-500"
                  value={settingsPrincipalName}
                  onChange={(e) => setSettingsPrincipalName(e.target.value)}
                  autoFocus
                />
                <p className="text-xs text-gray-500 mt-1">
                  This will be used for comments, requests, and Quick Access directories.
                </p>
              </div>
              {settingsPrincipalName && (
                <div className="bg-gray-50 rounded-lg p-3">
                  <div className="text-xs text-gray-500 mb-1">Quick Access directories:</div>
                  <div className="font-mono text-xs text-gray-600 space-y-0.5">
                    <div>principals/{settingsPrincipalName.toLowerCase()}/</div>
                    <div>principals/{settingsPrincipalName.toLowerCase()}/notes/</div>
                    <div>principals/{settingsPrincipalName.toLowerCase()}/requests/</div>
                    <div>principals/{settingsPrincipalName.toLowerCase()}/observations/</div>
                  </div>
                </div>
              )}
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={() => {
                  if (settingsPrincipalName.trim()) {
                    setPrincipalName(settingsPrincipalName.trim());
                    setShowSettingsModal(false);
                  }
                }}
                disabled={!settingsPrincipalName.trim()}
                className="flex-1 px-4 py-2 bg-agency-600 text-white rounded-lg hover:bg-agency-700 disabled:opacity-50"
              >
                Save
              </button>
              {principalName && (
                <button
                  onClick={() => {
                    setSettingsPrincipalName(principalName);
                    setShowSettingsModal(false);
                  }}
                  className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
                >
                  Cancel
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Template Modal */}
      {showTemplateModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Create from Template</h2>
            <div className="space-y-2">
              {templates.map((template) => (
                <button
                  key={template.id}
                  onClick={() => handleCreateFromTemplate(template.id)}
                  disabled={isCreating}
                  className="w-full text-left px-4 py-3 rounded-lg border border-gray-200 hover:border-agency-500 hover:bg-agency-50 transition-colors disabled:opacity-50"
                >
                  <div className="font-medium text-gray-900">{template.name}</div>
                  <div className="text-sm text-gray-500">{template.description}</div>
                </button>
              ))}
            </div>
            <div className="flex justify-end mt-6">
              <button
                onClick={() => setShowTemplateModal(false)}
                className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function DocBenchPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-full text-gray-400">Loading...</div>}>
      <DocBenchContent />
    </Suspense>
  );
}
