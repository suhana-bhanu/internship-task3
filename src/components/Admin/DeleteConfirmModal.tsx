import { AlertTriangle } from 'lucide-react';

interface User {
  id: string;
  full_name: string;
  email: string;
}

interface DeleteConfirmModalProps {
  user: User;
  onClose: () => void;
  onConfirm: () => void;
}

export function DeleteConfirmModal({ user, onClose, onConfirm }: DeleteConfirmModalProps) {
  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md">
        <div className="flex items-center mb-4">
          <AlertTriangle className="w-8 h-8 text-red-500 mr-3" />
          <h3 className="text-xl font-bold text-gray-800">Confirm Deletion</h3>
        </div>

        <p className="text-gray-600 mb-6">
          Are you sure you want to delete user <strong>{user.full_name}</strong> ({user.email})?
          This action cannot be undone.
        </p>

        <div className="flex space-x-3">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors font-medium"
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            className="flex-1 bg-red-600 text-white py-2 rounded-lg hover:bg-red-700 transition-colors font-medium"
          >
            Delete User
          </button>
        </div>
      </div>
    </div>
  );
}
