var HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  context: __dirname + '/src',
  entry: './index.js',
  output: {
    path: './build',
    publicPath: '',
    filename: 'app.js'
  },
  module: {
    loaders: [
      { test: /\.glsl$/, loader: 'shader-loader' },
      { test: /\.css$/, loader: 'style-loader!css-loader' },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: 'babel?presets[]=es2015'
      }
    ]
  },
  plugins: [new HtmlWebpackPlugin()]
};
