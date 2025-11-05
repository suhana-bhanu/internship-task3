import { useAuth } from '../../contexts/AuthContext';
import { LogOut, User, Users } from 'lucide-react';

interface HeaderProps {
  currentView: 'profile' | 'users';
  onViewChange: (view: 'profile' | 'users') => void;
}

export function Header({ currentView, onViewChange }: HeaderProps) {
  const { userProfile, signOut } = useAuth();

  const isAdmin = userProfile?.role_name === 'admin';

  return (
    <header className="bg-white shadow">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center space-x-8">
            <h1 className="text-xl font-bold text-gray-800">User Management System</h1>

            <nav className="flex space-x-4">
              <button
                onClick={() => onViewChange('profile')}
                className={`flex items-center px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                  currentView === 'profile'
                    ? 'bg-blue-100 text-blue-700'
                    : 'text-gray-600 hover:bg-gray-100'
                }`}
              >
                <User className="w-4 h-4 mr-2" />
                My Profile
              </button>

              {isAdmin && (
                <button
                  onClick={() => onViewChange('users')}
                  className={`flex items-center px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                    currentView === 'users'
                      ? 'bg-blue-100 text-blue-700'
                      : 'text-gray-600 hover:bg-gray-100'
                  }`}
                >
                  <Users className="w-4 h-4 mr-2" />
                  Manage Users
                </button>
              )}
            </nav>
          </div>

          <div className="flex items-center space-x-4">
            <div className="text-right">
              <p className="text-sm font-medium text-gray-800">{userProfile?.full_name}</p>
              <p className="text-xs text-gray-500 capitalize">{userProfile?.role_name}</p>
            </div>

            {userProfile?.profile_picture_url ? (
              <img
                src={userProfile.profile_picture_url}
                alt={userProfile.full_name}
                className="w-10 h-10 rounded-full object-cover"
              />
            ) : (
              <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                <span className="text-blue-600 font-medium">
                  {userProfile?.full_name.charAt(0).toUpperCase()}
                </span>
              </div>
            )}

            <button
              onClick={signOut}
              className="flex items-center px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 rounded-md transition-colors"
            >
              <LogOut className="w-4 h-4 mr-2" />
              Logout
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
