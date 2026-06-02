const admin = require("firebase-admin");

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const places = [
  {
    name: "RIZQY FOTOCOPY MURAH",
    address:
      "Jl. Karang Menjangan VII No.14, Mojo, Airlangga, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.27047722405225,
    longitude: 112.76089639520896,
    rating: 4.7,
    phone: "087755373520",
    photo_url:
      "https://lh3.googleusercontent.com/gps-cs-s/APNQkAFCOCT7AbT7ftNZOF2YegAmEndXtZ1kmK7sIeTORCSojax4aRIT9DacypWb0uRoai-MaqbZIbvFSVvWeWunAMZ_rn47L4m3Id2uIpAXG5L7UXMBiPR0pmqhfMs5GtF3yj10dbAg=w408-h544-k-no",
    open_hours: "08.30-21.00",
    category: "fotocopy",
  },
  {
    name: "Fotocopy Nirwana",
    address:
      "Jl. Dharmawangsa Barat No.35b i no, Airlangga, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.273860923261669,
    longitude: 112.7563812676839,
    rating: 4.5,
    phone: "081330200079",
    photo_url:
      "https://lh3.googleusercontent.com/gps-cs-s/APNQkAGXqDLK7w4uKGXdHdgXhQ3c7ZzSP9I5WxZ0Nd-bq-QV-bkfOYitdmYzPudYLdcqQBtVTmg224IazstTsdMUOC7dWgbHzGm76Vz5snmCcr7EMFb3OnNA1YDk3ObQ5KCKrvt0FASv=w408-h544-k-no",
    open_hours: "08.00-21.00",
    category: "fotocopy",
  },
  {
    name: "Budaya Print Percetakan & Fotocopy",
    address:
      "JJl. Karang Menjangan II No.10, Mojo, Kec. Gubeng, Surabaya, Jawa Timur 60285",
    latitude: -7.266869332347309,
    longitude: 112.76204528341557,
    rating: 5.0,
    phone: "081231413580",
    photo_url:
      "https://lh3.googleusercontent.com/gps-cs-s/APNQkAGb-CK_tZWmvsxXHaO9kS6ra_paDGYj32C589hmo2DolyegugwpUZwZnykrtz4hrpv9b6BuSF1PhdjrhjQjD4mBV8iOKt8WDIOfUsghaYDcu_-ZhoChTd7awp4g_-CHy6xRCjZ2=w408-h306-k-no",
    open_hours: "07.00-22.00",
    category: "fotocopy",
  },
  {
    name: "Centro Dua (2) Digital Copier",
    address:
      "Jl. Dharmawangsa Barat No.31, Airlangga, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.269435519740686,
    longitude: 112.75463254617362,
    rating: 4.2,
    phone: "082131563619",
    photo_url:
      "https://lh3.googleusercontent.com/gps-proxy/ALd4DhFVuxecZ7taXHAZeipBMkjBngviwwZTQakp0Joc761d2FAFsDpLOt9ifpHE53HnCdZ9oY9Ooquiuoy6_C3Dp4jNR_D-2M6u5zyqY89vfJpz-7950kmS008QUFSvMuWqTxE3J73rhCOFUx1rmAlLCVk-ICKwL9u_fSK0a7CB-ZtrHIpAUP5YhqO83SbFfbGXL1adnw=w408-h306-k-no",
    open_hours: "08.00-21.00",
    category: "fotocopy",
  },
  {
    name: "Wahyu Foto Copy",
    address:
      "JL. Dharmahusada, No. 14-A, Pacarkembang, Tambaksari, Mulyorejo, Surabaya, Jawa Timur 60132",
    latitude: -7.266764988538605,
    longitude: 112.77817688868818,
    rating: 4.2,
    phone: "0315923631",
    photo_url:
      "https://streetviewpixels-pa.googleapis.com/v1/thumbnail?panoid=y8et8O-ev18GCmD8xx_jSA&cb_client=search.gws-prod.gps&w=408&h=240&yaw=358.11273&pitch=0&thumbfov=100",
    open_hours: "-",
    category: "fotocopy",
  },
  {
    name: "Puskrip Karmen, Print , Foto Copy 24 Jam",
    address:
      "Jl. Karang Menjangan No.113A, Mojo, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.271433712098228,
    longitude: 112.76149542907089,
    rating: 4.1,
    phone: "085337333314",
    photo_url:
      "https://lh3.googleusercontent.com/gps-cs-s/APNQkAFB1px8cYhUw7JFbYRCeNlMWJtAcQrep814W5FWiRW2xYFgOaw-xzkcZ3GkIO31jK0Ul6XpVqBS2gl9A7GfLHvmAxSPQ9Yuir9zxI0tXto5WMr6TeXn9yux399q2KAyt1CU5bK9wl0iuuYC=w408-h544-k-no",
    open_hours: "24 jam",
    category: "fotocopy",
  },
  {
    name: "Snopy Copy Center",
    address:
      "Jl. Karang Menjangan No.82, Airlangga, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.270058488322233,
    longitude: 112.76121749136036,
    rating: 5.0,
    phone: "081217113139",
    photo_url:
      "https://lh3.googleusercontent.com/gps-proxy/ALd4DhHsex_5QwEg0SZTKhVf5Vt8UbN22Jp-FZeD4B2cVFe2WZIbmSAoYfQefSP7_V7nK4-6QSKv5Y88eq_IYUPZGC1km_HxHHWxe6hQrc1K-PLfCYaI-8EzdpgsT5EqtBSTYD1FcWVTinwF-JolGHOLRmocOxKxlqLcDKnO9vIv4XenJimlrCLf_8lt5wmlJkOmVsnOp5k=w408-h306-k-no",
    open_hours: "08.00–20.00",
    category: "fotocopy",
  },
  {
    name: "PUSKRIP PRINT-FOTOCOPY-WARNET-RENTAL KOMPUTER-DIGITAL PRINTING",
    address:
      "Jl. Kalijudan No.24, Kalijudan, Kec. Mulyorejo, Surabaya, Jawa Timur 60114",
    latitude: -7.258221235097959,
    longitude: 112.77456162999016,
    rating: 4.3,
    phone: "082138982158",
    photo_url:
      "https://lh3.googleusercontent.com/gps-cs-s/APNQkAFdO-go4hArWP33xBDFxlkmQQuYIKayUooYpbCA-B8TSguGcyz65jEi_7Qy_YFrJO3zbgEeah4LPfwbAxoXHxAShiAcPo74s1Nup1NJrkUMXUmrHdkAg40uiPRE4JwwYGFhhQkxtQ=w408-h544-k-no",
    open_hours: "24 jam",
    category: "fotocopy",
  },
  {
    name: "Ramayana Fotokopi & Percetakan",
    address:
      "Jl. Dharmawangsa No.106 A, Airlangga, Gubeng, Surabaya, East Java 60286",
    latitude: -7.271881217921049,
    longitude: 112.75628626067527,
    rating: 4.4,
    phone: "0315032117",
    photo_url:
      "https://lh3.googleusercontent.com/gps-proxy/ALd4DhH2SLHD8rwgp-kvFS6R0Iki6brzHK71mBQcxOQBc_fK3E3BSSW1izmOOUKNMTHEtWlckFAF0NXGzSQwI28fUmA8yRntA8vUJ1tmfJKm_RdmOggX34ULS_0dlH3AIMjvPvJVlEeMivCoPCSBXPI-gWpwRw5c42QbEdvurkyNcctLQw8fXRYxh2G8hNpkriv7g9b9S4I=w408-h306-k-no",
    open_hours: "08.30–17.30",
    category: "fotocopy",
  },
  {
    name: "Pijar Copy Center",
    address:
      "Jl. Karang Menjangan No.64, Mojo, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.2699058296548635,
    longitude: 112.76014511519469,
    rating: 3.9,
    phone: "085762673046",
    photo_url:
      "https://lh3.googleusercontent.com/gps-cs-s/APNQkAFBYawbmHr5NRktH8HeeUmTXiTbwKL3y3wEZ88Gap4JSQ_oRc1qVmn_NBl6x6VNzpTExwjgAehfd6EETbHgAvUGaD4Vtu78Sg643QX28LFUtEY6t1LD4_6-qeRda9s7cu-tCoOuow=w408-h306-k-no",
    open_hours: "08.00–22.00",
    category: "fotocopy",
  },
  {
    name: "Joyo Corner Print & Foto Copy",
    address:
      "Jl. Karang Menjangan No.82, RT.001/RW.08, Airlangga, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.270280550396813,
    longitude: 112.76120686067529,
    rating: 4.8,
    phone: "085645079609",
    photo_url:
      "https://lh3.googleusercontent.com/gps-cs-s/APNQkAHd_kPb_L6T8jTsXjrbt0SMvttjQWKeoqgTlkn3waRzqX5DLZXe6wPGAjya2nlGMfkpIh8OEHKk21YywXcuHvl5fz9Qgf22jUZMtTnPbusMmJdgXNnOBTIqQ0aDCYhCCGQnSUl4=w408-h306-k-no",
    open_hours: "08.00–22.00",
    category: "fotocopy",
  },
  {
    name: "Aneka Jaya Fotocopy",
    address:
      "Jl. Dharmawangsa No.130, Airlangga, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.274281584990937,
    longitude: 112.75581576862008,
    rating: 4.2,
    phone: "0315031446",
    photo_url:
      "https://lh3.googleusercontent.com/gps-proxy/ALd4DhGABf_pbUei4LAHJUJ_VBOZxIhOMwN1icADZNAGfFi3rkzrrHGoRt4rxECIIzO3Z4LiRNOy4cc_2QbweOF5Qo3RM1Ka8bM0tYD4jBOAozCw2RyX0nAFiHtlD9wep0a-_BKUovjkZkQ_TZbPdVSVLQDbgw1F2EeB0Ch7LP09w1ElYFOpP2GFWJ2GKSfYm4YuaCxbVt4=w408-h306-k-no",
    open_hours: "07.30–20.00",
    category: "fotocopy",
  },
  {
    name: "Foto Copy HOKY",
    address:
      "Jl. Jojoran I No.94, Mojo, Kec. Gubeng, Surabaya, Jawa Timur 60285",
    latitude: -7.270936792485583,
    longitude: 112.76691947656485,
    rating: 4.6,
    phone: "081515737292",
    photo_url:
      "https://lh3.googleusercontent.com/gps-proxy/ALd4DhF6qkocjH1MvnsKWF_I2GkMITiX4rTiFAYE-9GbUXbRc1xBVMUDukkE_mlGuDSEF6PpFgu4o6oteeINJ1AYEtT_ZRRcn-3HgwBoJ8L3F_NYPqQgB56SuRky6_4kTIdA4Bjd8y-gy4qUwowai8K_bZMEvJH6HhsmtGIYQk78AxwbS_trJ-7kKC2O-epIg5rfdFtKWWU=w408-h306-k-no",
    open_hours: "07.00–21.00",
    category: "fotocopy",
  },
  {
    name: "Foto Copy Murah Harapan Jaya Dharmawangsa",
    address:
      "L DHARMAWANGSA NO : 116 SURABAYA Pindahan dari gubeng kertajaya 9 d no :35, Airlangga, Kec. Gubeng, Surabaya, Jawa Timur 60286",
    latitude: -7.273342432446002,
    longitude: 112.75571027644337,
    rating: 4.7,
    phone: "082145874561",
    photo_url:
      "https://lh3.googleusercontent.com/gps-cs-s/APNQkAFXR8fkdBTTalWrfTW2FLmVsKTKKO6Rlsc6xhK1i2jWjpxo-szC3CaIfcim_W5HYY-KvU6s2nbcvXQWENm6C5vllgAzwIk1lQGr3x8vY1V0yCDJFQF81x063zr5VdRJx7rds7Se=w427-h240-k-no",
    open_hours: "08.00–21.00",
    category: "fotocopy",
  },
];

async function uploadData() {
  try {
    for (const place of places) {
      await db.collection("places").add(place);
      console.log(`✓ ${place.name}`);
    }

    console.log("================================");
    console.log("SEMUA DATA BERHASIL DIUPLOAD");
    console.log("================================");

    process.exit();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

uploadData();
