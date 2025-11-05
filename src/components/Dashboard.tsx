import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Header } from './Layout/Header';
import { ProfilePage } from './Profile/ProfilePage';
import { UserManagement } from './Admin/UserManagement';

export function Dashboard() {
  const { userProfile } = useAuth();
  const [currentView, setCurrentView] = useState<'profile' | 'users'>('profile');

  const isAdmin = userProfile?.role_name === 'admin';

  return (
    <div className="min-h-screen bg-gray-100">
      <Header currentView={currentView} onViewChange={setCurrentView} />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {currentView === 'profile' && <ProfilePage />}
        {currentView === 'users' && isAdmin && <UserManagement />}
      </main>
    </div>
  );
}
