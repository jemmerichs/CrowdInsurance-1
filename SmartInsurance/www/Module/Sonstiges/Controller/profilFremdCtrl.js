appController.controller('profilFremdCtrl',function($scope, $http, $state, $stateParams, apiendpoint){

    $scope.profilID = $stateParams.investor.personID;
    console.log($scope.profilID);

    $http.get(apiendpoint.url + '/api/smartinsurance/profil/' + $scope.profilID).success(function(response) {
         $scope.profil = response[0];
    });

    $scope.versicherungen= [];
    $scope.bewertungen = [];

        $http.get(apiendpoint.url + '/api/smartinsurance/versicherung/person/' + $scope.profilID).success(function(response) {
            $scope.versicherungen = response;

            $scope.avgBewertung = 0;

            var getBewertung = function(i){
              $http.get(apiendpoint.url + '/api/smartinsurance/versicherung' + $scope.versicherungen[i].id + '/bewertungen').success(function(response) {
                    if(angular.isDefined(response[0])) {

                        $scope.bewertungen.push(response);

                        $scope.pos = Number($scope.bewertungen[i][1].count);
                        $scope.neg = Number($scope.bewertungen[i][2].count);

                        $scope.bewertung = $scope.pos - $scope.neg;

                        $scope.avgBewertung +=  $scope.bewertung;

                        $scope.versicherungen[i].bewertung = $scope.bewertung;
                    } else {
                        $scope.bewertungen.push($scope.bewertung = [
                            {count: 0},
                            {count: 0},
                            {count: 0}
                        ]);
                        $scope.versicherungen[i].bewertung = 0;
                    }
                });
            }

            for (var i = 0; i < $scope.versicherungen.length; i++){
              getBewertung(i);
            }
        });

     $scope.versicherungShow = function(id) {
        $state.go("app.investitionInfo",{id: id});
    };


});
