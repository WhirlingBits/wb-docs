import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';
import * as fs from 'fs';
import * as path from 'path';

// 🔥 Updated Interfaces
interface RepoConfig {
  id: string;
  label: string;
  description: string;
  category: string;
  displayMode: 'toplevel' | 'category';
  editUrl: string;
  githubUrl: string;
  enabled: boolean;
}

interface CategoryConfig {
  id: string;
  label: string;
  icon: string;
  description: string;
  position: 'left' | 'right';
}

interface ConfigData {
  repositories: RepoConfig[];
  settings: {
    categories: CategoryConfig[];
    versioning: {
      enabled: boolean;
      showUnreleased: boolean;
      currentLabel: string;
      currentPath: string;
    };
    branding: {
      title: string;
      tagline: string;
      organizationName: string;
    };
  };
}

// 🔥 Load configuration
function loadRepositoriesConfig(): ConfigData {
  const configPath = path.join(__dirname, 'docusaurus-config.json');
  
  try {
    const configContent = fs.readFileSync(configPath, 'utf-8');
    const config: ConfigData = JSON.parse(configContent);
    
    // Filter enabled repositories
    config.repositories = config.repositories.filter(r => r.enabled);
    
    console.log(`📦 Loaded ${config.repositories.length} enabled repositories`);
    
    return config;
  } catch (error) {
    console.error('❌ Error loading docusaurus-config.json:', error);
    
    // Fallback
    return {
      repositories: [],
      settings: {
        categories: [],
        versioning: {
          enabled: true,
          showUnreleased: true,
          currentLabel: 'Next',
          currentPath: 'next',
        },
        branding: {
          title: 'WhirlingBits Documentation',
          tagline: 'ESP-IDF Component Documentation',
          organizationName: 'WhirlingBits',
        },
      },
    };
  }
}

function docsDirectoryExists(repoId: string): boolean {
  const docsPath = path.join(__dirname, repoId);
  
  if (!fs.existsSync(docsPath)) {
    return false;
  }
  
  const files = fs.readdirSync(docsPath);
  const hasMarkdownFiles = files.some(file => 
    file.endsWith('.md') || file.endsWith('.mdx')
  );
  
  const hasVersionedDocs = fs.existsSync(path.join(__dirname, `${repoId}_versioned_docs`));
  
  return hasMarkdownFiles || hasVersionedDocs;
}

function loadVersionsForRepo(repoId: string): string[] {
  const versionsPath = path.join(__dirname, `${repoId}_versions.json`);
  
  try {
    if (fs.existsSync(versionsPath)) {
      const versionsContent = fs.readFileSync(versionsPath, 'utf-8');
      const versions = JSON.parse(versionsContent);
      
      console.log(`   📋 Versions for ${repoId}: ${versions.join(', ')}`);
      
      return versions;
    }
  } catch (error) {
    console.warn(`⚠️  Error loading ${repoId}_versions.json:`, error);
  }

  return [];
}

function generateVersionConfig(repoId: string, settings: ConfigData['settings']) {
  const versions = loadVersionsForRepo(repoId);
  const docsPath = path.join(__dirname, repoId);

  let hasCurrentDocs = false;
  if (fs.existsSync(docsPath)) {
    const files = fs.readdirSync(docsPath);
    hasCurrentDocs = files.some(file => 
      file.endsWith('.md') || file.endsWith('.mdx')
    );
  }

  const versionedDocsPath = path.join(__dirname, `${repoId}_versioned_docs`);
  const hasVersionedDocs = fs.existsSync(versionedDocsPath);

  let validVersions: string[] = [];
  if (hasVersionedDocs && versions.length > 0) {
    validVersions = versions.filter(version => {
      const versionPath = path.join(versionedDocsPath, `version-${version}`);
      const exists = fs.existsSync(versionPath);

      if (exists) {
        const files = fs.readdirSync(versionPath);
        const hasMd = files.some(f => f.endsWith('.md') || f.endsWith('.mdx'));
        if (!hasMd) {
          console.warn(`   ⚠️  Version ${version}: ${repoId}_versioned_docs/version-${version}/ exists but no MD files!`);
          return false;
        }
      }
      
      if (!exists) {
        console.warn(`   ⚠️  Version ${version} in ${repoId}_versions.json but ${repoId}_versioned_docs/version-${version}/ missing!`);
      }
      return exists;
    });
  }
  
  console.log(`   📋 Debug ${repoId}:`);
  console.log(`      - ${repoId}_versions.json: ${versions.length > 0 ? versions.join(', ') : 'none'}`);
  console.log(`      - ${repoId}_versioned_docs/ exists: ${hasVersionedDocs}`);
  console.log(`      - valid ${repoId}_versioned_docs/: ${validVersions.length > 0 ? validVersions.join(', ') : 'none'}`);
  console.log(`      - current docs (${repoId}/*.md): ${hasCurrentDocs}`);

  if (validVersions.length === 0 && !hasCurrentDocs) {
    console.warn(`⚠️  No documentation found for ${repoId}`);
    return null;
  }

  if (validVersions.length === 0 && hasCurrentDocs) {
    console.log(`   ℹ️  ${repoId}: Only current (no versioning)`);
    return {
      disableVersioning: true,
      includeCurrentVersion: true,
    };
  }

  if (validVersions.length > 0 && !hasCurrentDocs) {
    const lastVersion = validVersions[0];

    console.log(`   ✅ ${repoId}: Only versioning without current (lastVersion: ${lastVersion})`);

    return {
      lastVersion: lastVersion,
      includeCurrentVersion: false,
      disableVersioning: false,
    };
  }

  console.log(`   ✅ ${repoId}: Current + ${validVersions.length} versions`);

  return {
    lastVersion: 'current',
    includeCurrentVersion: true,
    disableVersioning: false,
  };
}

// 🔥 Load configuration
const repoConfig = loadRepositoriesConfig();
const settings = repoConfig.settings;
const categories = settings.categories || [];

// 🔥 Filter repositories with existing docs
const repositories = repoConfig.repositories.filter(repo => {
  const exists = docsDirectoryExists(repo.id);
  
  if (!exists) {
    console.warn(`⚠️  Skipping ${repo.id}: Directory ${repo.id}/ not found`);
    console.warn(`   Run './generate-docs.sh' to generate documentation`);
  } else {
    console.log(`✅ ${repo.id}: Documentation found (category: ${repo.category}, display: ${repo.displayMode})`);
  }
  
  return exists;
});

console.log(`\n📚 Active repositories: ${repositories.length} of ${repoConfig.repositories.length}`);

// 🔥 Group repositories by category (only for displayMode='category')
const reposByCategory = repositories
  .filter(repo => repo.displayMode === 'category')
  .reduce((acc, repo) => {
    if (!acc[repo.category]) {
      acc[repo.category] = [];
    }
    acc[repo.category].push(repo);
    return acc;
  }, {} as Record<string, RepoConfig[]>);

console.log(`\n📊 Repositories by display mode:`);
const toplevelRepos = repositories.filter(r => r.displayMode === 'toplevel');
if (toplevelRepos.length > 0) {
  console.log(`   📌 Top-Level: ${toplevelRepos.map(r => r.id).join(', ')}`);
}
console.log(`\n📁 By category:`);
Object.entries(reposByCategory).forEach(([category, repos]) => {
  console.log(`   ${category}: ${repos.map(r => r.id).join(', ')}`);
});

// 🔥 Generate docs plugins
const docsPlugins = repositories
  .map(repo => {
    const versionConfig = generateVersionConfig(repo.id, settings);

    if (!versionConfig) {
      console.warn(`⚠️  Skipping plugin for ${repo.id}: No valid configuration`);
      return null;
    }

    console.log(`\n🔧 Plugin config for ${repo.id}:`);
    console.log(`   Label: ${repo.label}`);
    console.log(`   Category: ${repo.category}`);
    console.log(`   Display Mode: ${repo.displayMode}`);
    console.log(`   Path: ${repo.id}`);
    console.log(`   Versioning: ${versionConfig.disableVersioning ? 'disabled' : 'enabled'}`);
    if (!versionConfig.disableVersioning) {
      console.log(`   Last Version: ${versionConfig.lastVersion}`);
      console.log(`   Include Current: ${versionConfig.includeCurrentVersion}`);
    }
    
    const basePath = repo.id;
    
    const sidebarPath = fs.existsSync(path.join(__dirname, basePath, 'sidebars.json'))
      ? `./${basePath}/sidebars.json`
      : undefined;
    
    return [
      '@docusaurus/plugin-content-docs',
      {
        id: repo.id,
        path: basePath,
        routeBasePath: repo.id,
        ...(sidebarPath && { sidebarPath }),
        editUrl: repo.editUrl,

        lastVersion: versionConfig.lastVersion,
        includeCurrentVersion: versionConfig.includeCurrentVersion,
        disableVersioning: versionConfig.disableVersioning,
        
        remarkPlugins: [],
        rehypePlugins: [],
      },
    ];
  })
  .filter((plugin): plugin is NonNullable<typeof plugin> => plugin !== null);

const config: Config = {
  title: settings.branding.title,
  tagline: settings.branding.tagline,
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://docs.whirlingbits.de',
  baseUrl: '/',

  organizationName: settings.branding.organizationName,
  projectName: 'wb-docs',
  deploymentBranch: 'gh-pages',
  trailingSlash: false,

  onBrokenLinks: 'warn',
  onBrokenAnchors: 'warn',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: false,
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  plugins: docsPlugins,
  themes: ['@docusaurus/theme-mermaid'],

  markdown: {
    mermaid: true,
    format: 'detect',
  },

  themeConfig: {
    image: 'img/wb-social-card.jpg',
    
    colorMode: {
      defaultMode: 'light',
      disableSwitch: true,
      respectPrefersColorScheme: true,
    },
    
    algolia: {
      appId: '4GR9PMMKXX',
      apiKey: '638385848c29478b55def3a3a03818f2',
      indexName: 'whirlingbits',
      contextualSearch: true,
      externalUrlRegex: 'docs\\.whirlingbits\\.de',
      replaceSearchResultPathname: {
        from: '/docs/',
        to: '/',
      },
      searchParameters: {},
      searchPagePath: 'search',
    },
    
    navbar: {
      title: settings.branding.organizationName,
      logo: {
        alt: `${settings.branding.organizationName} Logo`,
        src: 'img/Whirlingbits_logo.png',
      },
      items: [
        ...repositories
          .filter(repo => repo.displayMode === 'toplevel')
          .map(repo => {
            console.log(`✅ Navbar top-level item: ${repo.label}`);
            return {
              type: 'doc' as const,
              docId: 'index',
              docsPluginId: repo.id,
              label: repo.label,
              position: 'left' as const,
            };
          }),
        ...categories
          .map(category => {
            const categoryRepos = reposByCategory[category.id] || [];
            
            if (categoryRepos.length === 0) {
              console.warn(`⚠️  Category '${category.label}' has no repositories`);
              return null;
            }
            
            console.log(`✅ Navbar category dropdown: ${category.label} (${categoryRepos.length} repos)`);
            
            return {
              type: 'dropdown' as const,
              label: category.label,
              position: category.position,
              items: categoryRepos.map(repo => ({
                type: 'doc' as const,
                docId: 'index',
                docsPluginId: repo.id,
                label: repo.label,
              })),
            };
          })
          .filter((item): item is NonNullable<typeof item> => item !== null),
        ...repositories
          .map(repo => {
            const versions = loadVersionsForRepo(repo.id);
            const docsPath = path.join(__dirname, repo.id);
            
            let hasCurrentDocs = false;
            if (fs.existsSync(docsPath)) {
              const files = fs.readdirSync(docsPath);
              hasCurrentDocs = files.some(file => 
                file.endsWith('.md') || file.endsWith('.mdx')
              );
            }
            
            const versionedDocsPath = path.join(__dirname, `${repo.id}_versioned_docs`);
            let validVersions: string[] = [];
            if (fs.existsSync(versionedDocsPath) && versions.length > 0) {
              validVersions = versions.filter(version => {
                const versionPath = path.join(versionedDocsPath, `version-${version}`);
                return fs.existsSync(versionPath);
              });
            }
            
            const totalVersions = hasCurrentDocs ? validVersions.length + 1 : validVersions.length;
            
            if (totalVersions <= 1) {
              console.log(`   ⏭️  No version dropdown for ${repo.id} (only ${totalVersions} version)`);
              return null;
            }
            
            console.log(`   ✅ Version dropdown for ${repo.id} (${totalVersions} versions)`);
            
            return {
              type: 'docsVersionDropdown' as const,
              position: 'right' as const,
              docsPluginId: repo.id,
              dropdownActiveClassDisabled: false,
              dropdownItemsAfter: [
                {
                  to: `/${repo.id}/versions`,
                  label: 'All versions',
                },
              ],
            };
          })
          .filter((item): item is NonNullable<typeof item> => item !== null),
        {
          href: `https://github.com/${settings.branding.organizationName}`,
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: repositories.slice(0, 5).map(repo => ({
            label: `${repo.label} API`,
            to: `/${repo.id}`,
          })),
        },
        {
          title: 'Repositories',
          items: repositories.slice(0, 5).map(repo => ({
            label: repo.label,
            href: repo.githubUrl,
          })),
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub Organization',
              href: `https://github.com/${settings.branding.organizationName}`,
            },
            ...repositories
              .filter(repo => {
                const versions = loadVersionsForRepo(repo.id);
                const versionedDocsPath = path.join(__dirname, `${repo.id}_versioned_docs`);
                
                if (!fs.existsSync(versionedDocsPath) || versions.length === 0) {
                  return false;
                }
                
                return versions.some(version => {
                  const versionPath = path.join(versionedDocsPath, `version-${version}`);
                  return fs.existsSync(versionPath);
                });
              })
              .map(repo => ({
                label: `${repo.label} Versions`,
                to: `/${repo.id}/versions`,
              })),
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} ${settings.branding.organizationName}. Version ${require('./package.json').version}`,
    },
    
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['c', 'cpp', 'bash', 'json', 'yaml'],
    },
    
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: true,
      },
    },
    
  } satisfies Preset.ThemeConfig,
  
  staticDirectories: ['static'],
};

export default config;