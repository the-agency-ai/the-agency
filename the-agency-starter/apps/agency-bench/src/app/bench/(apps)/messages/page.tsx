'use client';

import { useState, useEffect } from 'react';
import { isTauri, getProjectRoot } from '@/lib/tauri';

interface Message {
  id: number;
  timestamp: string;
  from_type: string;
  from_name: string;
  to_type: string;
  to_name: string | null;
  subject: string | null;
  content: string;
}

interface MessageRecipient {
  message_id: number;
  recipient_type: string;
  recipient_name: string;
  read_at: string | null;
}

interface MessageWithStatus {
  message: Message;
  recipients: MessageRecipient[];
}

export default function MessagesPage() {
  const [messages, setMessages] = useState<MessageWithStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedMessage, setSelectedMessage] = useState<MessageWithStatus | null>(null);
  const [filter, setFilter] = useState<'all' | 'unread' | 'read'>('all');

  useEffect(() => {
    async function loadMessages() {
      try {
        if (isTauri) {
          const { invoke } = await import('@tauri-apps/api/core');
          const data: MessageWithStatus[] = await invoke('list_messages', { limit: 100 });
          setMessages(data);
        }
      } catch (err) {
        console.error('Failed to load messages:', err);
      } finally {
        setLoading(false);
      }
    }

    loadMessages();
  }, []);

  // Filter messages
  const filteredMessages = messages.filter((m) => {
    if (filter === 'all') return true;
    const hasUnread = m.recipients.some((r) => r.read_at === null);
    if (filter === 'unread') return hasUnread;
    if (filter === 'read') return !hasUnread;
    return true;
  });

  // Format timestamp
  const formatTime = (ts: string) => {
    const date = new Date(ts + 'Z');
    return date.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  // Get delivery status
  const getDeliveryStatus = (recipients: MessageRecipient[]) => {
    const total = recipients.length;
    const read = recipients.filter((r) => r.read_at !== null).length;
    if (read === total) return { label: 'All read', color: 'text-green-600 bg-green-50' };
    if (read > 0) return { label: `${read}/${total} read`, color: 'text-yellow-600 bg-yellow-50' };
    return { label: 'Unread', color: 'text-gray-600 bg-gray-100' };
  };

  return (
    <div className="flex h-[calc(100vh-8rem)] gap-4">
      {/* Message List */}
      <div className="w-96 bg-white rounded-xl border border-gray-200 flex flex-col">
        {/* Filters */}
        <div className="p-3 border-b border-gray-200">
          <div className="flex gap-2">
            {(['all', 'unread', 'read'] as const).map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-3 py-1 text-sm rounded-full capitalize ${
                  filter === f
                    ? 'bg-agency-600 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
        </div>

        {/* Message List */}
        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="text-center py-8 text-gray-400">Loading...</div>
          ) : filteredMessages.length === 0 ? (
            <div className="text-center py-8 text-gray-400">No messages</div>
          ) : (
            filteredMessages.map((m) => {
              const status = getDeliveryStatus(m.recipients);
              const isSelected = selectedMessage?.message.id === m.message.id;
              const hasUnread = m.recipients.some((r) => r.read_at === null);

              return (
                <button
                  key={m.message.id}
                  onClick={() => setSelectedMessage(m)}
                  className={`w-full text-left p-3 border-b border-gray-100 hover:bg-gray-50 ${
                    isSelected ? 'bg-agency-50' : ''
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        {hasUnread && (
                          <span className="w-2 h-2 bg-agency-600 rounded-full flex-shrink-0" />
                        )}
                        <span className="font-medium text-sm text-gray-900 truncate">
                          {m.message.from_type}:{m.message.from_name}
                        </span>
                      </div>
                      {m.message.subject && (
                        <div className="text-sm text-gray-700 truncate mt-0.5">
                          {m.message.subject}
                        </div>
                      )}
                      <div className="text-xs text-gray-500 truncate mt-0.5">
                        {m.message.content.substring(0, 60)}
                        {m.message.content.length > 60 ? '...' : ''}
                      </div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <div className="text-xs text-gray-400">{formatTime(m.message.timestamp)}</div>
                      <div className={`text-xs px-1.5 py-0.5 rounded mt-1 ${status.color}`}>
                        {status.label}
                      </div>
                    </div>
                  </div>
                </button>
              );
            })
          )}
        </div>

        {/* Stats */}
        <div className="p-3 border-t border-gray-200 text-xs text-gray-500">
          {messages.length} messages total
        </div>
      </div>

      {/* Message Detail */}
      <div className="flex-1 bg-white rounded-xl border border-gray-200 flex flex-col">
        {selectedMessage ? (
          <>
            <div className="p-4 border-b border-gray-200">
              <div className="flex items-start justify-between">
                <div>
                  <div className="text-sm text-gray-500">
                    From: <span className="text-gray-900 font-medium">
                      {selectedMessage.message.from_type}:{selectedMessage.message.from_name}
                    </span>
                  </div>
                  <div className="text-sm text-gray-500 mt-1">
                    To: <span className="text-gray-900">
                      {selectedMessage.message.to_type}
                      {selectedMessage.message.to_name && `:${selectedMessage.message.to_name}`}
                    </span>
                  </div>
                  {selectedMessage.message.subject && (
                    <div className="text-lg font-medium text-gray-900 mt-2">
                      {selectedMessage.message.subject}
                    </div>
                  )}
                </div>
                <div className="text-sm text-gray-400">
                  {formatTime(selectedMessage.message.timestamp)}
                </div>
              </div>
            </div>

            <div className="flex-1 p-4 overflow-y-auto">
              <div className="prose prose-sm max-w-none whitespace-pre-wrap">
                {selectedMessage.message.content}
              </div>
            </div>

            {/* Recipients Status */}
            <div className="p-4 border-t border-gray-200 bg-gray-50">
              <div className="text-xs font-medium text-gray-500 mb-2">Delivery Status</div>
              <div className="flex flex-wrap gap-2">
                {selectedMessage.recipients.map((r, i) => (
                  <div
                    key={i}
                    className={`text-xs px-2 py-1 rounded ${
                      r.read_at ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-600'
                    }`}
                  >
                    {r.recipient_type}:{r.recipient_name}
                    {r.read_at && (
                      <span className="ml-1 text-green-600">✓</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Select a message to view details
          </div>
        )}
      </div>
    </div>
  );
}
