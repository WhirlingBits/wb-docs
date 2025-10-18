module.exports = {
  title: 'Whirlingbits Dokumentation',
  url: 'https://whirlingbits.de',
  baseUrl: '/',
  favicon: 'img/favicon.ico',
  organizationName: 'whirlingbits',
  projectName: 'wb-docs',

  instances: [
    {
      id: 'core',
      title: 'WB-IDF-Core',
      docs: [
        {
          source: './wb-idf-core/docs', // Pfad zur Doku im geklonten wb-idf-core-Repo
          sidebar: 'auto'
        }
      ]
    },
//    {
//      id: 'api',
   //   title: 'WB-IDF-API',
 //     docs: [
   //     {
   //       source: './wb-idf-api/docs', // Pfad zur Doku im geklonten wb-idf-api-Repo
   //       sidebar: 'auto'
   //     }
    //  ]
   // }
  ],

  themeConfig: {
    navbar: {
      title: 'Whirlingbits Docs',
      items: [
        { to: 'core/', label: 'Core', position: 'left' },
        { to: 'api/', label: 'API', position: 'left' }
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Links',
          items: [
            {
              label: 'GitLab',
              href: 'https://gitlab.whirlingbits.de/',
            },
          ],
        },
      ],
    },
  },
};