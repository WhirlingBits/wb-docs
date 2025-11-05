import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/wb-idf-core/">
            Get Started with wb-idf-core →
          </Link>
        </div>
      </div>
    </header>
  );
}

function RepositoryShowcase() {
  return (
    <section className={styles.repositoryShowcase}>
      <div className="container">
        <Heading as="h2" className="text--center margin-bottom--lg">
          Available Components
        </Heading>
        <div className="row">
          <div className="col col--12">
            <div className={clsx('card', styles.repositoryCard)}>
              <div className="card__header">
                <Heading as="h3">wb-idf-core</Heading>
              </div>
              <div className="card__body">
                <p>
                  Core functionality and utilities for ESP-IDF projects. Includes I2C, SPI, UART drivers and more.
                </p>
              </div>
              <div className="card__footer">
                <div className={styles.cardButtons}>
                  <Link
                    className="button button--primary button--block"
                    to="/wb-idf-core/">
                    View Documentation
                  </Link>
                  <Link
                    className="button button--secondary button--outline button--block"
                    to="https://github.com/WhirlingBits/wb-idf-core">
                    View on GitHub
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function QuickLinks() {
  const quickLinks = [
    {
      title: '📚 API Reference',
      description: 'Explore the complete API documentation for all components',
      link: '/wb-idf-core/',
    },
    {
      title: '🚀 Getting Started',
      description: 'Learn how to integrate WhirlingBits components into your project',
      link: '/wb-idf-core/',
    },
    {
      title: '💡 Examples',
      description: 'Browse code examples and best practices',
      link: '/wb-idf-core/',
    },
    {
      title: '🐛 Report Issues',
      description: 'Found a bug? Let us know on GitHub',
      link: 'https://github.com/WhirlingBits/wb-idf-core/issues',
    },
  ];

  return (
    <section className={styles.quickLinks}>
      <div className="container">
        <Heading as="h2" className="text--center margin-bottom--lg">
          Quick Links
        </Heading>
        <div className="row">
          {quickLinks.map((item, idx) => (
            <div key={idx} className="col col--3 margin-bottom--lg">
              <Link to={item.link} className={clsx('card', styles.quickLinkCard)}>
                <div className="card__body">
                  <Heading as="h4">{item.title}</Heading>
                  <p>{item.description}</p>
                </div>
              </Link>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title}`}
      description="ESP-IDF Component Documentation for WhirlingBits Projects">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <RepositoryShowcase />
        <QuickLinks />
      </main>
    </Layout>
  );
}
