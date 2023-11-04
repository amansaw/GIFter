window._GIPHY = (function() {
    var apiKey = "GYwmyel0oQhSZ3wG0sWSDNaFcpv8Fgbv";
    var _results = null;

    return { //public API
        getApiKey: function() {
            return apiKey;
        },
        getResults: function() {
            return _results;
        },
        setResults: function(results) {
          _results = results
        }
    };
}());

