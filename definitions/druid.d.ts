// Type definitions for druid.io version 0.6.158
// http://druid.io
//
// Author: Vadim Ogievetsky

declare module Druid {

  // http://druid.io/docs/0.6.158/Querying.html#query-context
  interface Context {
    timeout?: number;
    priority?: number;
    queryId?: number;
    useCache?: boolean;
    populateCache?: boolean;
    bySegment?: boolean;
    finalize?: boolean;

    // Undocumented:
    doAggregateTopNMetricFirst?: boolean;

    // Or whatever...
    [key: string]: any;
  }

  // http://druid.io/docs/0.6.158/GeographicQueries.html
  interface SpatialBound {
    type: string;

    // Specific to type: "rectangular"
    minCoords?: number[];
    maxCoords?: number[];

    // Specific to type: "radius"
    coords?: number[];
    radius?: number;
  }

  // http://druid.io/docs/0.6.158/Filters.html
  interface Filter {
    type: string;
    dimension?: string;

    // Specific to type: "selector"
    value?: string;

    // Specific to type: "regex"
    pattern?: string;

    // Specific to type: "javascript"
    "function"?: string;

    // Specific to type: "spatial"
    bound?: SpatialBound;

    // Specific to type: "not"
    field?: Filter;

    // Specific to type: "and" | "or"
    fields?: Filter[];
  }

  // http://druid.io/docs/0.6.158/Aggregations.html
  interface Aggregation {
    type: string;
    name?: string;
    fieldName?: string;

    fieldNames?: string[];

    // Specific to type: "javascript"
    fnAggregate?: string;
    fnCombine?: string;
    fnReset?: string;

    // Specific to type: "cardinality"
    byRow?: boolean;

    // Specific to type: "approxHistogramFold"
    resolution?: number;
    numBuckets?: number;
    lowerLimit?: number;
    upperLimit?: number;
  }

  // http://druid.io/docs/0.6.158/Post-aggregations.html
  interface PostAggregation {
    type: string;
    name?: string;
    fn?: string;
    fields?: PostAggregation[];

    // Specific to type: "fieldAccess"
    fieldName?: string;

    // Specific to type: "constant"
    value?: number;

    // Specific to type: "javascript"
    fieldNames?: string[];
    "function"?: string;

    // Specific to type: "equalBuckets"
    numBuckets?: number;

    // Specific to type: "buckets"
    bucketSize?: number;
    offset?: number;

    // Specific to type: "quantile"
    probability?: number;

    // Specific to type: "quantiles"
    probabilities?: number[];
  }

  // http://druid.io/docs/0.6.158/Granularities.html
  interface Granularity {
    type: string;
    duration?: number; // or string?

    period?: string;
    timeZone?: string;
    origin?: string;
  }

  // http://druid.io/docs/0.6.158/LimitSpec.html
  interface OrderByColumnSpec {
    dimension: string;
    direction: string;
  }
  interface LimitSpec {
    type: string;
    limit: number;
    columns: Array<string|OrderByColumnSpec>;
  }

  // http://druid.io/docs/0.6.158/Having.html
  interface Having {
    type: string
    aggregation?: string
    value?: string

    // Specific to type: "not"
    havingSpec?: Having;

    // Specific to type: "and" | "or"
    havingSpecs?: Having[];
  }

  // http://druid.io/docs/0.6.158/SearchQuerySpec.html
  interface SearchQuerySpec {
    type: string;

    // Specific to type: "insensitive_contains"
    value?: string;

    // Specific to type: "fragment"
    values?: string[];
  }

  // http://druid.io/docs/0.6.158/SegmentMetadataQuery.html
  interface ToInclude {
    type: string;

    // Specific to type: "list"
    columns?: string[];
  }

  // http://druid.io/docs/0.6.158/DimensionSpecs.html
  interface DimExtractionFn {
    type: string;

    // Specific to type: "regex" | "partial"
    expr?: string;

    // Specific to type: "searchQuery"
    query?: string;

    // Specific to type: "time"
    timeFormat?: string;
    resultFormat?: string;

    // Specific to type: "javascript"
    "function"?: string;
  }
  interface DimensionSpec {
    type: string;
    dimension?: string;
    outputName?: string;

    // Specific to type: "extraction"
    dimExtractionFn?: DimExtractionFn;
  }

  // http://druid.io/docs/0.6.158/TopNMetricSpec.html
  interface TopNMetricSpec {
    type: string;

    // Specific to type: "numeric" | "inverted"
    metric?: string|TopNMetricSpec;

    // Specific to type: "lexicographic" | "alphaNumeric"
    previousStop?: any;
  }

  // http://druid.io/docs/0.6.158/SelectQuery.html
  interface PagingSpec {
    pagingIdentifiers: any; // ToDo: find better docs for this / ask FJ
    threshold: number
  }

  // http://druid.io/docs/0.6.158/DataSource.html
  interface DataSource {
    type: string;

    // Specific to type: "table"
    name?: string;

    // Specific to type: "union"
    dataSources?: string[];

    // Specific to type: "query"
    query?: Query;
  }

  // http://druid.io/docs/0.6.158/Querying.html
  interface Query {
    queryType: string;
    dataSource: string|DataSource;
    context?: Context;
    intervals?: string[];
    filter?: Filter;
    aggregations?: Aggregation[];
    postAggregations?: PostAggregation[];
    granularity?: string|Granularity;

    // Used by queryType: "groupBy" and "select";
    dimensions?: Array<string|DimensionSpec>;

    // Specific to queryType: "groupBy"
    // http://druid.io/docs/0.6.158/GroupByQuery.html
    limitSpec?: LimitSpec;
    having?: Having;

    // Specific to queryType: "search"
    // http://druid.io/docs/0.6.158/SearchQuery.html
    searchDimensions?: string[];
    query?: SearchQuerySpec;
    sort?: string; // ToDo: revisit after clarification

    // Specific to queryType: "segmentMetadata"
    // http://druid.io/docs/0.6.158/SegmentMetadataQuery.html
    toInclude?: ToInclude;
    merge?: boolean;

    // Specific to queryType: "timeBoundary"
    // http://druid.io/docs/0.6.158/TimeBoundaryQuery.html
    bound?: string;

    // Specific to queryType: "timeseries"
    // http://druid.io/docs/0.6.158/TimeseriesQuery.html
    // <nothing>

    // Specific to queryType: "topN"
    // http://druid.io/docs/0.6.158/TopNQuery.html
    dimension?: string|DimensionSpec;
    threshold?: number;
    metric?: string|TopNMetricSpec;

    // Specific to queryType: "select"
    // http://druid.io/docs/0.6.158/SelectQuery.html
    metrics?: string[];
    pagingSpec?: PagingSpec;
  }

  interface IntrospectResult {
    dimensions: string[];
    metrics: string[];
  }
}
