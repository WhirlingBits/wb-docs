import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';
import * as fs from 'fs';
import * as path from 'path';

// 🔥 Interface für Repository-Config
interface RepoConfig {
  id: string;
  label: string;
  description: string;
  editUrl: string;
  githubUrl: string;
  enabled: boolean;
}

interface ConfigData {
  repositories: RepoConfig[];
  settings: {
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

// 🔥 Lade Config aus JSON
function loadRepositoriesConfig(): ConfigData {
  const configPath = path.join(__dirname, 'repositories.json');
  
  try {
    const configContent = fs.readFileSync(configPath, 'utf-8');
    const config: ConfigData = JSON.parse(configContent);
    
    // Nur aktivierte Repositories
    config.repositories = config.repositories.filter(r => r.enabled);
    
    console.log(`📦 Geladene Repositories: ${config.repositories.map(r => r.id).join(', ')}`);
    
    return config;
  } catch (error) {
    console.error('❌ Error loading repositories.json:', error);
    
    // Fallback to empty config
    return {
      repositories: [],
      settings: {
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

// ✅ FIXED: Multi-Instance Structure - Check <repo>/ (not docs-<repo>/)
function docsDirectoryExists(repoId: string): boolean {
  const docsPath = path.join(__dirname, repoId);
  
  if (!fs.existsSync(docsPath)) {
    return false;
  }
  
  // ✅ Check for Markdown files directly in root (flat structure)
  const files = fs.readdirSync(docsPath);
  const hasMarkdownFiles = files.some(file => 
    file.endsWith('.md') || file.endsWith('.mdx')
  );
  
  // ✅ Multi-Instance: Check for <repo>_versioned_docs/
  const hasVersionedDocs = fs.existsSync(path.join(__dirname, `${repoId}_versioned_docs`));
  
  return hasMarkdownFiles || hasVersionedDocs;
}

// ✅ FIXED: Multi-Instance - Load from <repo>_versions.json
function loadVersionsForRepo(repoId: string): string[] {
  const versionsPath = path.join(__dirname, `${repoId}_versions.json`);
  
  try {
    if (fs.existsSync(versionsPath)) {
      const versionsContent = fs.readFileSync(versionsPath, 'utf-8');
      const versions = JSON.parse(versionsContent);
      
      console.log(`   📋 Versionen für ${repoId}: ${versions.join(', ')}`);
      
      return versions;
    }
  } catch (error) {
    console.warn(`⚠️  Fehler beim Laden von ${repoId}_versions.json:`, error);
  }

  // Fallback: No versions
  return [];
}

// ✅ FIXED: Multi-Instance Structure
function generateVersionConfig(repoId: string, settings: ConfigData['settings']) {
  const versions = loadVersionsForRepo(repoId);
  const docsPath = path.join(__dirname, repoId);

  // ✅ Check for Markdown files directly in root (current)
  let hasCurrentDocs = false;
  if (fs.existsSync(docsPath)) {
    const files = fs.readdirSync(docsPath);
    hasCurrentDocs = files.some(file => 
      file.endsWith('.md') || file.endsWith('.mdx')
    );
  }

  // ✅ Multi-Instance: Check for <repo>_versioned_docs/
  const versionedDocsPath = path.join(__dirname, `${repoId}_versioned_docs`);
  const hasVersionedDocs = fs.existsSync(versionedDocsPath);

  // ✅ Validate that versions REALLY exist
  let validVersions: string[] = [];
  if (hasVersionedDocs && versions.length > 0) {
    validVersions = versions.filter(version => {
      const versionPath = path.join(versionedDocsPath, `version-${version}`);
      const exists = fs.existsSync(versionPath);

      // Check if Markdown files exist
      if (exists) {
        const files = fs.readdirSync(versionPath);
        const hasMd = files.some(f => f.endsWith('.md') || f.endsWith('.mdx'));
        if (!hasMd) {
          console.warn(`   ⚠️  Version ${version}: ${repoId}_versioned_docs/version-${version}/ existiert aber keine MD-Dateien!`);
          return false;
        }
      }
      
      if (!exists) {
        console.warn(`   ⚠️  Version ${version} in ${repoId}_versions.json aber ${repoId}_versioned_docs/version-${version}/ fehlt!`);
      }
      return exists;
    });
  }
  
  console.log(`   📋 Debug ${repoId}:`);
  console.log(`      - ${repoId}_versions.json: ${versions.length > 0 ? versions.join(', ') : 'none'}`);
  console.log(`      - ${repoId}_versioned_docs/ exists: ${hasVersionedDocs}`);
  console.log(`      - valid ${repoId}_versioned_docs/: ${validVersions.length > 0 ? validVersions.join(', ') : 'none'}`);
  console.log(`      - current docs (${repoId}/*.md): ${hasCurrentDocs}`);

  // ✅ Case 1 - No docs at all
  if (validVersions.length === 0 && !hasCurrentDocs) {
    console.warn(`⚠️  No documentation found for ${repoId}`);
    return null;
  }

  // ✅ Case 2 - ONLY current (no versioning)
  if (validVersions.length === 0 && hasCurrentDocs) {
    console.log(`   ℹ️  ${repoId}: Only current (no versioning)`);
    return {
      disableVersioning: true,
      includeCurrentVersion: true,
    };
  }

  // ✅ Case 3 - ONLY versions (no current)
  if (validVersions.length > 0 && !hasCurrentDocs) {
    const lastVersion = validVersions[0];

    console.log(`   ✅ ${repoId}: Only versioning without current (lastVersion: ${lastVersion})`);

    return {
      lastVersion: lastVersion,
      includeCurrentVersion: false,
      disableVersioning: false,
    };
  }

  // ✅ Case 4 - BOTH (current + versions)
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

// 🔥 Filter only repositories with existing docs
const repositories = repoConfig.repositories.filter(repo => {
  const exists = docsDirectoryExists(repo.id);
  
  if (!exists) {
    console.warn(`⚠️  Skipping ${repo.id}: Directory ${repo.id}/ not found`);
    console.warn(`   Run './generate-docs.sh' to generate documentation`);
  } else {
    console.log(`✅ ${repo.id}: Documentation found`);
  }
  
  return exists;
});

console.log(`\n📚 Active repositories: ${repositories.length} of ${repoConfig.repositories.length}`);

// ✅ FIXED: Multi-Instance Structure
const docsPlugins = repositories
  .map(repo => {
    const versionConfig = generateVersionConfig(repo.id, settings);

    // ✅ Skip if no valid config
    if (!versionConfig) {
      console.warn(`⚠️  Skipping plugin for ${repo.id}: No valid configuration`);
      return null;
    }

    console.log(`\n🔧 Plugin config for ${repo.id}:`);
    console.log(`   Label: ${repo.label}`);
    console.log(`   Path: ${repo.id}`);
    console.log(`   Versioning: ${versionConfig.disableVersioning ? 'disabled' : 'enabled'}`);
    if (!versionConfig.disableVersioning) {
      console.log(`   Last Version: ${versionConfig.lastVersion}`);
      console.log(`   Include Current: ${versionConfig.includeCurrentVersion}`);
    }
    
    const basePath = repo.id;
    
    // ✅ Sidebar-Pfad (Multi-Instance: <repo>/sidebars.json)
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

        // ✅ Spread ONLY the necessary options
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

  // GitHub Pages deployment
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
        // ✅ REMOVED: docs plugin (nur Repository-Plugins)
        docs: false,
        
        blog: false,
        
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  // 🔥 Dynamisch generierte Plugins
  plugins: docsPlugins,

  // Markdown-Konfiguration
  markdown: {
    mermaid: true,
    format: 'detect',
  },

  themeConfig: {
    image: 'img/wb-social-card.jpg',
    
    colorMode: {
      defaultMode: 'light',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    
    // ✅ Algolia Search Integration
    algolia: {
      // The application ID provided by Algolia
      appId: '4GR9PMMKXX',

      // Public API key: it is safe to commit it
      apiKey: '638385848c29478b55def3a3a03818f2',

      indexName: 'whirlingbits',

      // Optional: see doc section below
      contextualSearch: true,

      // Optional: Specify domains where the navigation should occur through window.location instead on history.push. Useful when our Algolia config crawls multiple documentation sites and we want to navigate with window.location.href to them.
      externalUrlRegex: 'docs\\.whirlingbits\\.de',

      // Optional: Replace parts of the item URLs from Algolia. Useful when using the same search index for multiple deployments using a different baseUrl. You can use regexp or string in the `from` param. For example: localhost:3000 vs myCompany.com/docs
      replaceSearchResultPathname: {
        from: '/docs/', // or as RegExp: /\/docs\//
        to: '/',
      },

      // Optional: Algolia search parameters
      searchParameters: {},

      // Optional: path for search page that enabled by default (`false` to disable it)
      searchPagePath: 'search',
    },
    
    navbar: {
      title: settings.branding.organizationName,
      logo: {
        alt: `${settings.branding.organizationName} Logo`,
        src: 'img/logo.svg',
      },
      items: [
        // ✅ REMOVED: Haupt-Docs Link (da kein docs plugin mehr)
        
        // 🔥 Repository-Links
        ...repositories.map(repo => ({
          type: 'doc' as const,
          docId: 'index',
          docsPluginId: repo.id,
          position: 'left' as const,
          label: repo.label,
        })),
        
        // ✅ Version-Dropdowns NUR für Repositories
        ...repositories
          .map(repo => {
            const versions = loadVersionsForRepo(repo.id);
            const docsPath = path.join(__dirname, repo.id);
            
            // Prüfe auf current
            let hasCurrentDocs = false;
            if (fs.existsSync(docsPath)) {
              const files = fs.readdirSync(docsPath);
              hasCurrentDocs = files.some(file => 
                file.endsWith('.md') || file.endsWith('.mdx')
              );
            }
            
            // ✅ Multi-Instance: Prüfe <repo>_versioned_docs/
            const versionedDocsPath = path.join(__dirname, `${repo.id}_versioned_docs`);
            let validVersions: string[] = [];
            if (fs.existsSync(versionedDocsPath) && versions.length > 0) {
              validVersions = versions.filter(version => {
                const versionPath = path.join(versionedDocsPath, `version-${version}`);
                return fs.existsSync(versionPath);
              });
            }
            
            // Zähle verfügbare Versionen
            const totalVersions = hasCurrentDocs ? validVersions.length + 1 : validVersions.length;
            
            // ✅ Zeige Dropdown nur wenn mehr als 1 Version verfügbar
            if (totalVersions <= 1) {
              console.log(`   ⏭️  Kein Version-Dropdown für ${repo.id} (nur ${totalVersions} Version)`);
              return null;
            }
            
            console.log(`   ✅ Version-Dropdown für ${repo.id} (${totalVersions} Versionen)`);
            
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
        
        // 🔥 GitHub-Link
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
          items: [
            // ✅ REMOVED: Getting Started Link (da kein docs/)
            ...repositories.map(repo => ({
              label: `${repo.label} API`,
              to: `/${repo.id}`,
            })),
          ],
        },
        {
          title: 'Repositories',
          items: repositories.map(repo => ({
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
                
                // Prüfe ob mindestens eine Version existiert
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
      copyright: `Copyright © ${new Date().getFullYear()} ${settings.branding.organizationName}. Built with Docusaurus.`,
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