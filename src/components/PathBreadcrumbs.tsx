import React from 'react';
import { ChevronRight, Home } from 'lucide-react';

interface PathBreadcrumbsProps {
  currentPath: string;
  onPathChange: (path: string) => void;
}

const PathBreadcrumbs: React.FC<PathBreadcrumbsProps> = ({ currentPath, onPathChange }) => {
  const pathSegments = currentPath.split('/').filter(segment => segment !== '');

  const handleNavigate = (index: number) => {
    if (index < 0) { // For home
      onPathChange('/');
      return;
    }
    const newPath = '/' + pathSegments.slice(0, index + 1).join('/');
    onPathChange(newPath);
  };

  return (
    <nav className="flex items-center text-sm sm:text-base text-gray-700 mb-4" aria-label="Breadcrumb">
      <ol className="inline-flex items-center space-x-1 md:space-x-2 rtl:space-x-reverse">
        <li className="inline-flex items-center">
          <button
            onClick={() => handleNavigate(-1)}
            className="inline-flex items-center text-gray-700 hover:text-blue-600 dark:text-gray-400 dark:hover:text-white"
          >
            <Home size={18} className="mr-1.5" />
            Root
          </button>
        </li>
        {pathSegments.map((segment, index) => (
          <li key={index}>
            <div className="flex items-center">
              <ChevronRight size={18} className="text-gray-400" />
              {index === pathSegments.length - 1 ? (
                <span className="ms-1 md:ms-2 font-medium text-gray-500 dark:text-gray-400 cursor-default truncate max-w-[100px] sm:max-w-[200px]" title={segment}>
                  {segment}
                </span>
              ) : (
                <button
                  onClick={() => handleNavigate(index)}
                  className="ms-1 md:ms-2 text-gray-700 hover:text-blue-600 dark:text-gray-400 dark:hover:text-white truncate max-w-[100px] sm:max-w-[150px]"
                  title={segment}
                >
                  {segment}
                </button>
              )}
            </div>
          </li>
        ))}
      </ol>
    </nav>
  );
};

export default PathBreadcrumbs; 