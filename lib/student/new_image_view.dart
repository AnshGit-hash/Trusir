// GestureDetector(
                                                    // onTap: () {
                                                    //   showDialog(
                                                    //     context: context,
                                                    //     barrierColor: Colors
                                                    //         .black
                                                    //         .withOpacity(0.3),
                                                    //     builder: (BuildContext
                                                    //         context) {
                                                    //       List<String> images =
                                                    //           formData.photo!
                                                    //               .split(',');

                                                    //       return Dialog(
                                                    //         backgroundColor:
                                                    //             Colors
                                                    //                 .transparent,
                                                    //         insetPadding:
                                                    //             const EdgeInsets
                                                    //                 .all(16),
                                                    //         shape:
                                                    //             RoundedRectangleBorder(
                                                    //           borderRadius:
                                                    //               BorderRadius
                                                    //                   .circular(
                                                    //                       20),
                                                    //         ),
                                                    //         child: Container(
                                                    //           padding:
                                                    //               const EdgeInsets
                                                    //                   .all(
                                                    //                   16.0),
                                                    //           decoration:
                                                    //               BoxDecoration(
                                                    //             color: Colors
                                                    //                 .white,
                                                    //             borderRadius:
                                                    //                 BorderRadius
                                                    //                     .circular(
                                                    //                         20),
                                                    //           ),
                                                    //           child: Column(
                                                    //             mainAxisSize:
                                                    //                 MainAxisSize
                                                    //                     .min,
                                                    //             children: [
                                                    //               const Text(
                                                    //                 "Uploaded Images",
                                                    //                 style:
                                                    //                     TextStyle(
                                                    //                   fontSize:
                                                    //                       18,
                                                    //                   fontWeight:
                                                    //                       FontWeight
                                                    //                           .bold,
                                                    //                 ),
                                                    //               ),
                                                    //               const SizedBox(
                                                    //                   height:
                                                    //                       10),
                                                    //               GridView
                                                    //                   .builder(
                                                    //                 shrinkWrap:
                                                    //                     true,
                                                    //                 physics:
                                                    //                     const NeverScrollableScrollPhysics(),
                                                    //                 gridDelegate:
                                                    //                     const SliverGridDelegateWithFixedCrossAxisCount(
                                                    //                   crossAxisCount:
                                                    //                       3,
                                                    //                   crossAxisSpacing:
                                                    //                       10,
                                                    //                   mainAxisSpacing:
                                                    //                       10,
                                                    //                 ),
                                                    //                 itemCount:
                                                    //                     images
                                                    //                         .length,
                                                    //                 itemBuilder:
                                                    //                     (context,
                                                    //                         index) {
                                                    //                   return Column(
                                                    //                     children: [
                                                    //                       Expanded(
                                                    //                         child:
                                                    //                             Image.network(
                                                    //                           images[index],
                                                    //                           fit: BoxFit.cover,
                                                    //                         ),
                                                    //                       ),
                                                    //                       const SizedBox(
                                                    //                           height: 5),
                                                    //                       Text(
                                                    //                         images[index],
                                                    //                         style:
                                                    //                             const TextStyle(
                                                    //                           fontSize: 8,
                                                    //                           color: Colors.blue,
                                                    //                         ),
                                                    //                         overflow:
                                                    //                             TextOverflow.ellipsis,
                                                    //                       ),
                                                    //                     ],
                                                    //                   );
                                                    //                 },
                                                    //               ),
                                                    //               const SizedBox(
                                                    //                   height:
                                                    //                       16),
                                                    //               Row(
                                                    //                 mainAxisAlignment:
                                                    //                     MainAxisAlignment
                                                    //                         .spaceEvenly,
                                                    //                 children: [
                                                    //                   ElevatedButton(
                                                    //                     onPressed:
                                                    //                         () {
                                                    //                       Navigator.pop(
                                                    //                           context);
                                                    //                       setState(
                                                    //                           () {
                                                    //                         isimageUploading =
                                                    //                             true;
                                                    //                       });
                                                    //                       handleUploadFromCamera();
                                                    //                     },
                                                    //                     child: const Text(
                                                    //                         "Camera"),
                                                    //                   ),
                                                    //                   ElevatedButton(
                                                    //                     onPressed:
                                                    //                         () {
                                                    //                       Navigator.pop(
                                                    //                           context);
                                                    //                       setState(
                                                    //                           () {
                                                    //                         isimageUploading =
                                                    //                             true;
                                                    //                       });
                                                    //                       handleUploadFromGallery();
                                                    //                     },
                                                    //                     child: const Text(
                                                    //                         "Gallery"),
                                                    //                   ),
                                                    //                 ],
                                                    //               ),
                                                    //             ],
                                                    //           ),
                                                    //         ),
                                                    //       );
                                                    //     },
                                                    //   );
                                                    // },
                                                  //   child: Image.network(
                                                  //     formData.photo!
                                                  //         .split(',')
                                                  //         .first,
                                                  //     fit: BoxFit.cover,
                                                  //   ),
                                                  // )
