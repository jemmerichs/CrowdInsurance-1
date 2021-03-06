appController.controller('loginCtrl', function(CacheHistoryReseter, $scope, $ionicPopup, $http, $state, moneyParser, moneyFormatter, apiendpoint) {

        $scope.daten = {};
        $scope.daten.email = "example@mail.com";
        $scope.daten.passwort = "1234";
        $scope.form = {};
        $scope.token;



        $scope.register = function () {
            $state.go('app.signup')
        };

        $scope.isValidPw = function(field) {
            if (field.$touched) {
                if (($scope.daten.passwort.length < 4 || $scope.daten.passwort.length > 32)) {
                    return true;
                }
                else {
                    return false;
                }
            }
            else {
                return false;
            }

        };


        $scope.login = function () {

            var url = apiendpoint.backend + "/api/smartbackend/auth/" +"email/";
            var data = {
                email: $scope.daten.email,
                password: $scope.daten.passwort
            }
            $http.post(url, data)
                .then(function(result) {
                    //                userService.userContext.saveToken(result.data);
                    $scope.token = result.data.access_token;
                    $http.defaults.headers.common['Authorization'] = "Bearer "+ $scope.token;
                    localStorage.setItem("authToken", $scope.token);
                    $ionicPopup.alert({
                        title: 'Login',
                        template: 'Sie haben sich erfolgreich eingeloggt.'
                    });
                    $state.go('app.uebersicht')
                    CacheHistoryReseter.reset();
                },function(error) {
                    console.log("Login fehlgeschlagen");
                    $ionicPopup.alert({
                        title: 'Login',
                        template: 'Sie haben eine ungültige Login Kombination eingegeben'

                    });
                })
        };

        $scope.auth = function (provider) {
            FB.login(function(response) {
                if (response.authResponse) {
                    console.log('Welcome!  Fetching your information.... ');
                    FB.api('/me', function(response) {
                        console.log('Good to see you, ' + response.name + '.');
                        console.log(response);

                        var url = apiendpoint.backend + "/api/smartbackend/auth/" +"facebook/";
                        var data = {
                            token: $scope.token
                        }
                        $http.post(url, data)
                        $http({
                            method: "GET",
                            url: url,
                        })
                            .then(function (result) {
                                    console.log('yes im ok');

                                }, function (error) {

                                    console.log('Error: ' + error);
                                }
                            )
                            .catch(function (response) {
                            });
                    });
                } else {
                    console.log('User cancelled login or did not fully authorize.');
                }
            })


        }
    }
);



