const path = require("path");
const DashboardPlugin = require('webpack-dashboard/plugin');
const webpack = require('webpack');

module.exports = () => ({
  module: {
    rules: [
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          { loader: 'elm-hot-webpack-loader' },
          {
            loader: 'elm-webpack-loader',
            options: {
              cwd: path.join(__dirname, '../'),
              debug: true
            }
          }
        ]
      }
    ]
  },

  plugins: [
    new webpack.HotModuleReplacementPlugin(),

  ],

  devServer: {
    contentBase: './src',
    historyApiFallback: true,
    inline: true,
    stats: {
      colors: true,
      entrypoints: true,
      timings: true,
      version: false,
      warnings: true,
    },
    hot: true,
    port: 3001
  }
});
