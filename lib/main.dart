import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';



final Logger _logger = Logger('MyApp');


void main() async {
 await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
 ); 
  //carregar variáveis ​​de ambiente
  await dotenv.load(fileName: ".env");

  // não durma
  KeepScreenOn.turnOn();
  
  //initializeDateFormatting();
  Intl.defaultLocale = 'pt_BR';

  //Configurações de localidade/idioma (iOS corrigido com Info.plist)
  Intl.withLocale('pt', () => 

    runApp(const MyApp())
  );
}


class SettingView extends StatefulWidget {

  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  String _selectedItemMy = "error";
  String _selectedItemBot = "error";
  final List<String> _items = ["error"];
  final FlutterTts tts = FlutterTts();
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();

    Future(() async {

      prefs = await SharedPreferences.getInstance();

      List voices = await tts.getVoices;

      _items.clear();
      for(var item in voices){
        var map = item as Map<Object?, Object?>;
        if(map["locale"].toString().toLowerCase().contains("pt")){
          _logger.info(map["name"]);
          _items.add(map["name"].toString());
        }
      }
      if(_items.isNotEmpty){
        
        _selectedItemMy = prefs.getString("voice_EU") ?? _items[0];
        _selectedItemBot = prefs.getString("voice_robô") ?? _items[0];
      }

      // refletir puxar para baixo
      setState(() {});
      
    });
  }

  Future<void> _changeVoice(String voiceName, String who, bool speak) async {

    prefs.setString("voice_$who", voiceName);

    if(!speak)
    {
      return;
    }

    await tts.stop();
    await tts.setVoice({
      'name': voiceName,
      'locale': 'pt-BR'
    });
    
    await tts.speak("$who voz foi definida");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Setting"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('voice_EU'),
            DropdownButton<String>(
              value: _selectedItemMy,
              items: _items
                  .map((String list) =>
                      DropdownMenuItem(value: list, child: Text(list)))
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedItemMy = value!;
                  _changeVoice(_selectedItemMy, "Eu", true);
                });
              },
            ),
            const Divider(height: 100),

            const Text('voz de robô'),
            DropdownButton<String>(
              value: _selectedItemBot,
              items: _items
                  .map((String list) =>
                      DropdownMenuItem(value: list, child: Text(list)))
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedItemBot = value!;
                  _changeVoice(_selectedItemBot, "robô", true);
                });
              },
            ),
          ]
        )
      ),
    );
  }
}

class CompleteForm extends StatefulWidget {
  const CompleteForm({Key? key}) : super(key: key);

  @override
  State<CompleteForm> createState() {
    return _CompleteFormState();
  }
}

class _CompleteFormState extends State<CompleteForm> {
  bool autoValidate = true;
  bool readOnly = false;
  bool showSegmentedControl = true;
  final _formKey = GlobalKey<FormBuilderState>();
  bool _ageHasError = false;
  bool _genderHasError = false;
  Map<String, dynamic> _formData = {};
  var genderOptions = ['Menino', 'Menina', 'Outro'];

  void _onChanged(dynamic val) => debugPrint(val.toString());

  void _submitForm() {

    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final formData = _formKey.currentState!.value;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyWidget(formData: _formData)),
      );
    }
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crie sua histórinha')),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              FormBuilder(
                key: _formKey,
                // enabled: false,
                onChanged: () {
                  _formKey.currentState!.save();
                  debugPrint(_formKey.currentState!.value.toString());
                },
                autovalidateMode: AutovalidateMode.disabled,
                initialValue: const {
                  'movie_rating': 'Calmo',
                  'best_language': 'Dart',
                  'age': '13',
                  'gender': 'Menino',
                  'languages_filter': ['Homem Aranha']
                },
                skipDisabled: true,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 15),
                    FormBuilderDropdown<String>(
                      name: 'gender',
                      decoration: InputDecoration(
                        labelText: 'Genero',
                        suffix: _genderHasError
                            ? const Icon(Icons.error)
                            : const Icon(Icons.check),
                        hintText: 'Selecione Genero',
                      ),
                      validator: FormBuilderValidators.compose(
                          [FormBuilderValidators.required()]),
                      items: genderOptions
                          .map((gender) => DropdownMenuItem(
                                alignment: AlignmentDirectional.center,
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      onSaved: (value) {
                  _formData['gender'] = value;
                },
                      onChanged: (val) {
                        setState(() {
                          _genderHasError = !(_formKey
                                  .currentState?.fields['gender']
                                  ?.validate() ??
                              false);
                        });
                      },
                      valueTransformer: (val) => val?.toString(),
                    ),                    

                    FormBuilderTextField(
                      autovalidateMode: AutovalidateMode.always,
                      name: 'age',
                      decoration: InputDecoration(
                        labelText: 'Idade',
                        suffixIcon: _ageHasError
                            ? const Icon(Icons.error, color: Colors.red)
                            : const Icon(Icons.check, color: Colors.green),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _ageHasError = !(_formKey.currentState?.fields['age']
                                  ?.validate() ??
                              false);
                        });
                      },
onSaved: (value) {
                  _formData['age'] = value;
                },                      
                      // valueTransformer: (text) => num.tryParse(text),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.max(70),
                      ]),
                      initialValue: '4',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),

                    FormBuilderFilterChip<String>(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: const InputDecoration(
                          labelText: 'Personagens'),
                      name: 'languages_filter',
                      selectedColor: Color.fromARGB(255, 91, 110, 194),
                      options: const [
                        FormBuilderChipOption(
                          value: 'Homem Aranha',
                          avatar: CircleAvatar(child: Text('HA')),
                        ),
                        FormBuilderChipOption(
                          value: 'Hulk',
                          avatar: CircleAvatar(child: Text('HU')),
                        ),
                        FormBuilderChipOption(
                          value: 'Homem de Ferro',
                          avatar: CircleAvatar(child: Text('HF')),
                        ),
                        FormBuilderChipOption(
                          value: 'Capitão América',
                          avatar: CircleAvatar(child: Text('CA')),
                        ),
                        FormBuilderChipOption(
                          value: 'Pantera Negra',
                          avatar: CircleAvatar(child: Text('PN')),
                        ),
                      ],
                      onSaved: (value) {
                  _formData['character'] = value;
                },
                      onChanged: _onChanged,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.minLength(1),
                        FormBuilderValidators.maxLength(4),
                      ]),
                    ),
                    FormBuilderSegmentedControl(
                      decoration: const InputDecoration(
                        labelText: 'Gênero',
                      ),
                      name: 'movie_rating',
                      // initialValue: 1,
                      // textStyle: TextStyle(fontWeight: FontWeight.bold),
                      //options: List.generate(5, (i) => i + 1)
                      options: ['Calmo','Comédia','Aventura', 'Terror'].map((number) => FormBuilderFieldOption(
                                value: number,
                                child: Text(
                                  number.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ))
                          .toList(),
                      onSaved: (value) {
                        _formData['movie_rating'] = value;
                      },
                    //  onChanged: _onChanged,
                    ),
                    FormBuilderSlider(
                      name: 'slider',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.min(6),
                      ]),
                      onSaved: (value) {
                  _formData['duration'] = value;
                },
                      onChanged: _onChanged,
                      min: 0.0,
                      max: 10.0,
                      initialValue: 7.0,
                      divisions: 20,
                      activeColor: Color.fromARGB(255, 66, 23, 221),
                      inactiveColor: Color.fromARGB(255, 141, 120, 245),
                      decoration: const InputDecoration(
                        labelText: 'Duração da história',
                      ),
                    ), 
                    FormBuilderSlider(
                      name: 'slider',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.min(6),
                      ]),
                      onSaved: (value) {
                  _formData['pace'] = value;
                },
                      onChanged: _onChanged,
                      min: 0.0,
                      max: 10.0,
                      initialValue: 7.0,
                      divisions: 20,
                      activeColor: Color.fromARGB(255, 66, 23, 221),
                      inactiveColor: Color.fromARGB(255, 141, 120, 245),
                      decoration: const InputDecoration(
                        labelText: 'Velocidade do narrador',
                      ),
                    ),                     
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(

                    
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white),
                        
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _formKey.currentState?.reset();
                      },
                      // color: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        'Reset',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                          ),
                    ),
                  ),
                ]
                ,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class NewWidget extends StatelessWidget {

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Widget')),
      body: Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
class MyWidget extends StatefulWidget {
  final Map<String, dynamic> formData;
 const MyWidget({Key? key, required this.formData}) : super(key: key);
 

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool _isLoading = true;
  String _data = '';

  List<Object> chatMessages = [];
  final FlutterTts tts = FlutterTts();
   
  @override
  void initState() {
    super.initState();

    _makeApiCall();
  }

  Future<void> _makeApiCall() async {
    
    final prefs = await SharedPreferences.getInstance();

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());   
    var receiveMsg = "";
    var receiveMsgSpeak = "";
    var receiveDone = false;
    List<Object> chatGPTMessages = [];
    ScrollController scrollController = ScrollController();
    print(widget.formData['movie_rating'].toString());
    String systemRequest = "Conte uma histõria para crianças com os personagens ${widget.formData['character'].join(', ')} um tom ${widget.formData['movie_rating'].toString()}. A história deve ter uma duração de ${widget.formData['duration'].toString()} minutos quando contada.";
    

    String systemRole = "Você é uma cuidadora de crianças";
    chatGPTMessages.add({"role": "system", "content": systemRole});
    chatGPTMessages.add({"role": "user", "content": systemRequest});
 // Duplicar com data e hora atuais adicionadas
    List<Object> chatMessagesClone = [
      {"role": "user", "content": DateFormat('É MM mês dd dia aaaa HH hora mm').format(DateTime.now())},
      ...chatGPTMessages
    ];
    print("chatGPTMessages: $chatGPTMessages");
    Uri url = Uri.parse("https://api.openai.com/v1/chat/completions");
    Map<String, String> headers = {
      'Content-type': 'application/json',
      "Authorization": "Bearer ${dotenv.get("OPEN_AI_API_KEY")}"
    };
    String body = json.encode({
      "frequency_penalty": 0,
      "max_tokens": 512,
      "messages": chatGPTMessages,
      "model": "gpt-3.5-turbo",
      "presence_penalty": 0,
      "stream": true,
      "temperature": 0.7,
      "top_p": 1
    });


    final request = http.Request('POST', url);
    request.headers.addAll(headers);
    request.body = body;
    request.followRedirects = false;

    final response = await request.send();
    int statusCode = response.statusCode;
    if(response.statusCode != 200)
    {
      setState(() {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Ocorreu um erro de comunicação ${response.statusCode}"),
        ));
      });

      return;
    }
  String _getVoiceName(String type)
  {
    return (type == "user" ? prefs.getString("voice_EU") : prefs.getString("voice_robo"))?? "";
  }

    await for (final message in response.stream.transform(utf8.decoder)) {
      
      message.split("\n").forEach((msg) {

        if(!msg.startsWith("data: "))
        {
          return;
        }

        var jsonMsg = msg.replaceFirst(RegExp("^data: "), "");

        if(jsonMsg == "[DONE]")
        {
          return;
        }

        final data = json.decode(jsonMsg);
        
        var content = data["choices"][0]["delta"]["content"];
        if(content == null){
          return;
        }
        receiveMsg += content;

        receiveMsgSpeak += content;
        
        // quando ainda não acabou
        if(!receiveDone)
        {
          // Verificação do número mínimo para evitar falar em pequenas quantidades de texto
          if(receiveMsgSpeak.length > 50)
          {
            var stopIndex = receiveMsgSpeak.indexOf(RegExp("、|。|\n"), 50);
            if(stopIndex > 0)
            {
              var speackMsg = receiveMsgSpeak.substring(0, stopIndex);
              receiveMsgSpeak = receiveMsgSpeak.substring(stopIndex+1, receiveMsgSpeak.length);

              () async {
                // falar mensagem recebida
                await tts.setVoice({'name': _getVoiceName("voice_robo"), 'locale': 'pt-BR'});
                await tts.speak(
                  speackMsg
                  ///receiveMsgSpeak
                );
              }();
            }
          }
        }
        receiveDone = true;
        _isLoading = false;
        // Definir texto para os últimos dados adicionados
        dynamic item = chatGPTMessages[chatGPTMessages.length-1];
        item["content"] = receiveMsg;
        chatGPTMessages[chatGPTMessages.length-1] = item;
      });
      
    }

    // Adicionar mensagem recebida
    chatGPTMessages.add({"role": "assistant", "content": ""});
    _logger.info(response.statusCode);
    setState(() {
      _isLoading = false;
      _data = receiveMsg;
    });
receiveDone = true;

    // Fale as mensagens recebidas restantes
    await tts.setVoice({'name': _getVoiceName("voice_robo"), 'locale': 'pt-BR'});
    await tts.speak(
      //receiveMsgSpeak
      receiveMsg
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Widget'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 16.0),
                  Text(_data),
                ],
              ),
            ),
    );
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speak Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      //home: const MyHomePage(title: 'Speak Chat'),
      home: CompleteForm (),
      //ロケール・言語設定（iOSはInfo.plistで直った）
      localizationsDelegates: const [
        // localizations delegateを追加
        //AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      //ロケール・言語設定（iOSはInfo.plistで直った）
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),

    );
  }
  
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  String lastWords = '';
  String systemRole = "Você é uma terapeuta que aplica técnicas de Coaching, constelação sistêmica e Programação Neuro Linguística. Você utiliza a terapia cognitivo comportamental como aporte científico. Aplica técnicas de coaching e PNL como estratégias alternativas no trabalho de desenvolvimento de cada indivíduo. Você domina os conteúdos de Coaching para aplicar na sua vida e carreira ou para desenvolver em programas de maximização de performance humana. Você é capaz de capacitar o cliente a tomar decisões, desenvolver habilidades e alcançar seus objetivos de forma independente. Você se comunica claramente e efetivamente com o cliente, usando técnicas de linguagem positiva e construtiva. Você se coloca no lugar do cliente e entender suas emoções e pontos de vista. Você responde com no máximo 100 palavras. Se necessário mais detalhes será requisitado";

  List<Object> chatMessages = [];
  final FlutterTts tts = FlutterTts();
  late SharedPreferences prefs;
  var inputTextcontroller = TextEditingController();
  ScrollController scrollController = ScrollController();


  @override
  void initState() {
    super.initState();


    Future(() async {

      prefs = await SharedPreferences.getInstance();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      

    });

    Future(() async {
      // Defina para emitir som do alto-falante
      await tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ]);

      // Adicionar áudio à fila (somente Android)
      if(Platform.isAndroid){
        tts.setQueueMode(1);
      }

      // Configuração de velocidade de fala
      await tts.setPitch(1.9);
      await tts.setSpeechRate(2.7);
    });

    // Abra a tela de configurações
    Future(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingView()),
      );
    });
  }

  String _getVoiceName(String type)
  {
    return (type == "user" ? prefs.getString("voice_EU") : prefs.getString("voice_robo"))?? "";
  }

  // Leia em voz alta
  Future<void> _speach(dynamic item) async {

    
    // pare e jogue
    await tts.stop();
    await tts.setVoice({
      'name': _getVoiceName(item["role"]),
      'locale': 'pt-BR'
    });
    
    await tts.speak(
      item["content"]
    );
  }

   // inicia a entrada de voz
  _speak()  {


    Future(() async {
      // pare de jogar
      await tts.stop();
    });

    // esvaziar a entrada
    setState(() {
      lastWords = "";
    });

    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        
        return const SpeechDialog();
      },
    ).then((value) {

      _logger.info("end dialog!");

      setState(() {
        if(value != null){
          lastWords = value;
        }
      });


      
      _ai();



    });
  }

    



  // メッセージを消去
  Future<void> _cleanMessage() async {
    setState(() {
      chatMessages.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('mensagem apagada'),
    ));
  }
  

  // ChatGPT
  Future<void> _ai() async {
    
    _logger.info("_ai");
    
    // Ignorar se não houver entrada
    if(lastWords == "")
    {
      return;
    }

    // rolar para baixo
    scrollController.jumpTo(scrollController.position.maxScrollExtent);

    
    // pare e jogue
    await tts.stop();
    await tts.setVoice({'name': _getVoiceName("user"), 'locale': 'pt-BR'});
    // await tts.speak(
    //   lastWords
    // );
    


    // Adicionar mensagem para enviar
    chatMessages.add({"role": "user", "content": lastWords});

    setState(() {
      
      inputTextcontroller.clear();

      FocusScopeNode currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus) {
        currentFocus.unfocus();
      }
    });




    chatMessages.add({"role": "system", "content": systemRole});

    // Duplicar com data e hora atuais adicionadas
    List<Object> chatMessagesClone = [
      {"role": "user", "content": DateFormat('É MM mês dd dia aaaa HH hora mm').format(DateTime.now())},
      ...chatMessages
    ];
    Uri url = Uri.parse("https://api.openai.com/v1/chat/completions");
    Map<String, String> headers = {
      'Content-type': 'application/json',
      "Authorization": "Bearer ${dotenv.get("OPEN_AI_API_KEY")}"
    };
    String body = json.encode({
      "frequency_penalty": 0,
      "max_tokens": 512,
      "messages": chatMessagesClone,
      "model": "gpt-3.5-turbo",
      "presence_penalty": 0,
      "stream": true,
      "temperature": 0.7,
      "top_p": 1
    });


    final request = http.Request('POST', url);
    request.headers.addAll(headers);
    request.body = body;
    request.followRedirects = false;

    final response = await request.send();


    if(response.statusCode != 200)
    {
      setState(() {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Ocorreu um erro de comunicação ${response.statusCode}"),
        ));
      });

      return;
    }

    _logger.info(response.statusCode);
    


    // Adicionar mensagem recebida
    chatMessages.add({"role": "assistant", "content": ""});
    setState(() {
      chatMessages = chatMessages;
    });

    var receiveMsg = "";
    var receiveMsgSpeak = "";
    var receiveDone = false;

    await for (final message in response.stream.transform(utf8.decoder)) {

      message.split("\n").forEach((msg) {

        if(!msg.startsWith("data: "))
        {
          return;
        }

        var jsonMsg = msg.replaceFirst(RegExp("^data: "), "");

        if(jsonMsg == "[DONE]")
        {
          return;
        }

        final data = json.decode(jsonMsg);
        

        var content = data["choices"][0]["delta"]["content"];
        if(content == null){
          return;
        }

        receiveMsg += content;
        print("receiveMsg $receiveMsg");

        receiveMsgSpeak += content;
        
        // quando ainda não acabou
        if(!receiveDone)
        {
          // Verificação do número mínimo para evitar falar em pequenas quantidades de texto
          if(receiveMsgSpeak.length > 50)
          {
            var stopIndex = receiveMsgSpeak.indexOf(RegExp("、|。|\n"), 50);
            if(stopIndex > 0)
            {
              var speackMsg = receiveMsgSpeak.substring(0, stopIndex);
              receiveMsgSpeak = receiveMsgSpeak.substring(stopIndex+1, receiveMsgSpeak.length);

              () async {
                // falar mensagem recebida
                await tts.setVoice({'name': _getVoiceName("voice_robo"), 'locale': 'pt-BR'});
                await tts.speak(
                  speackMsg
                  //receiveMsgSpeak
                );
              }();
            }
          }
        }

        // 最後に追加したデータにテキストを設定する
        dynamic item = chatMessages[chatMessages.length-1];
        item["content"] = receiveMsg;
        chatMessages[chatMessages.length-1] = item;
        
        setState(() {
          chatMessages = chatMessages;

          // rolar para baixo
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });

      });
      
    }

    receiveDone = true;

    // rolar para baixo
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tts.speak(
      "Teste"
    );
    // Fale as mensagens recebidas restantes
    await tts.setVoice({'name': _getVoiceName("voice_robo"), 'locale': 'pt-BR'});
    await tts.speak(
      //receiveMsgSpeak
      receiveMsg
    );



  }


  // alterar entrada de texto
  void _handleText(String e) {
    setState(() {
      lastWords = e;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingView()),
                );
              },
            ),
          ],
      ),
      body: Column(
          
        children: <Widget>[
          
          Expanded(
            child: Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(

                controller: scrollController,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: chatMessages.map((dynamic item)=>(
                    GestureDetector(
                      onTap: () {
                          _speach(item);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:[
                            Text(
                              item["role"] == "user" ? "EU　：" : "robô：",
                              style: TextStyle(
                                color: item["role"] == "user" ? Colors.blue : Colors.green, // definir a cor do texto para azul
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item["content"],
                                softWrap: true,
                              )
                            )
                          ]
                        )
                      )
                    )
                  )).toList()
                )
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child:Row(
            
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color.fromARGB(255, 0, 149, 255),
                    child:
                      IconButton(
                        onPressed: _cleanMessage,
                        icon: const Icon(Icons.cleaning_services),
                        iconSize: 18,
                        color:const Color.fromARGB(255, 255, 255, 255),
                      ),
                  ),
                ),
                Expanded(
                  child: 
                    TextFormField(
                      controller: inputTextcontroller,
                      enabled: true,
                      obscureText: false,
                      maxLines: null,
                      onChanged: _handleText,
                      decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: _speak,
                        icon: const Icon(Icons.mic),
                      ),
                                            
                    ),

                    )
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color.fromARGB(255, 0, 149, 255),
                  child:
                    IconButton(
                      onPressed: _ai,
                      icon: const Icon(Icons.send),
                      iconSize: 18,
                      color:const Color.fromARGB(255, 255, 255, 255),
                    ),
                )
              ],
            )
          )
        ],
      ),
    );
  }
}


class SpeechDialog extends StatefulWidget {
  
  const SpeechDialog({Key? key}) : super(key: key);

  @override
  SpeechDialogState createState() => SpeechDialogState();
}

class SpeechDialogState extends State<SpeechDialog> {
  String lastStatus = "";
  String lastError = "";
  String lastWords = "";
  stt.SpeechToText speech = stt.SpeechToText();
  ScrollController scrollController = ScrollController();
  double soundLevel = 0;
  



  @override
  void initState() {
    super.initState();

    
    Future(() async {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      
    });

    Future(() async {

      // Inicializar fala
      bool available = await speech.initialize(
        onError: (SpeechRecognitionError error) {
          if(!mounted) { return; }
          setState(() {
            lastError = '${error.errorMsg} - ${error.permanent}';
          });
        },
        onStatus: (String status) {
          if(!mounted) { return; }
          setState(() {
            lastStatus = status;
            _logger.info(status);

            // rolar para baixo
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          });
        }
      );

      if (available) {
        
        
        speech.listen(onResult: (SpeechRecognitionResult result) {
          if(!mounted) { return; }
          
          setState(() {
            lastWords = result.recognizedWords;
            
          });
        },
        onSoundLevelChange:(level){

          if(!mounted) { return; }

          setState(() {
            if(lastStatus != "listening")
            {
              // TODO:No iOS, o som pronto para gravação não soa, então quero tocá-lo, mas parece que não soa no estado speech.listen (vibração também é inútil)
            }
            lastStatus = "listening";
            soundLevel = level * -1 ;
          });
        },
        localeId: "pt-BR"
        );
      } else {
        _logger.info("The user has denied the use of speech recognition.");
      }
      
    });
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(

      title: Center(child:Text(lastStatus == "done" ? "fim" : lastStatus == "listening" ? "audição" : "em preparação $lastStatus")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Text(lastWords, style:const TextStyle(
                                color: Colors.cyan
                              ),),
            ),
          ),

        ],
      ),
    );
  }

  @override
  void dispose() {

    // executar as operações de limpeza necessárias
    super.dispose();

    speech.stop();
    
  }
}