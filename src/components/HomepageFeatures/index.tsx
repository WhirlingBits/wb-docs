import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: ReactNode;
  color?: string;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'ESP-IDF Components',
    Svg: require('@site/static/img/esp_idf_components.svg').default,
    color: '#ffffff',
    description: (
      <>
        Professional ESP-IDF components built with best practices.
        Fully documented APIs with examples and integration guides.
      </>
    ),
  },
  {
    title: 'Production Ready',
    Svg: require('@site/static/img/production_ready.svg').default,
    color: '#ffffff',
    description: (
      <>
        Battle-tested components used in real-world IoT projects.
        Comprehensive error handling and robust implementations.
      </>
    ),
  },
  {
    title: 'Open Source',
    Svg: require('@site/static/img/open_source.svg').default,
    color: '#ffffff',
    description: (
      <>
        All components are open source and available on GitHub.
        Contributions welcome! Built by the community, for the community.
      </>
    ),
  },
];

function Feature({title, Svg, description, color}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg 
          className={styles.featureSvg} 
          role="img"
          style={{ fill: color, color: color }}
        />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
