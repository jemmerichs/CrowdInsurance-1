appController.controller('versicherungDetailCtrl',function($scope, $http, $state, $stateParams, moneyParser, moneyFormatter, apiendpoint){


    $scope.versicherungId = $stateParams.id;

    $scope.noInvestor = true;


    $http.get(apiendpoint.url + '/api/smartinsurance/versicherung/' + $scope.versicherungId).success(function(response) {
         $scope.versicherung = response[0];
    });

    $http.get(apiendpoint.url + '/api/smartinsurance/versicherung/' + $scope.versicherungId +'/person').success(function(response) {
        $scope.investoren = response;
        $scope.noInvestor = false;
    })
    .error(function(response) {
    })
    
    $http.get(apiendpoint.url + '/api/smartinsurance/schadensfaelle/' + $scope.versicherungId).success(function(response) {
         $scope.schadensfaelle = response;

    })
    .error(function(response) {
    })
    

    $http.get(apiendpoint.url + '/api/smartinsurance/versicherung/' + $scope.versicherungId + '/invest')
        .success(function(response) {
            $scope.investitionBetrag = response[0].suminvestition;
        })
        .error(function(response) {
            $scope.investitionBetrag = "0,00 €";
        })

   
    $scope.gesamtSchaden = function () {
        var gesamtSchaden = 0;
        if (angular.isDefined($scope.schadensfaelle)) {
            for (var i = 0; i < $scope.schadensfaelle.length; i++) {
                gesamtSchaden = gesamtSchaden + moneyParser.moneyparsen($scope.schadensfaelle[i].schadenshoehe);
            };
        };
        return moneyFormatter.formatMoney(gesamtSchaden);
    };
    


    $scope.showInvestor = function () {
        // Verweis auf die Seite des Investors
    };

    $scope.editVersicherung = function () {
        $state.go("app.versicherungEdit", {id: $scope.versicherung.id});
    };

    $scope.showSchadensfaelle = function() {
        $state.go("app.schadensfaelle", {id: $scope.versicherung.id});
    };

    $scope.addSchadensfall = function () {
        $state.go("app.schadensfallMelden", {schaden: {versicherungID: $scope.versicherung.id}});
    };

    $scope.showSocial = function () {
        $state.go("app.versicherungSocial", {id: $scope.versicherung.id}); 
    };

});